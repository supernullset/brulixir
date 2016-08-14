defmodule BruceHedwig.ScoreServer do
  require Logger

  use GenServer
  # TODO: This registration will fail *in test* when this application is
  # added to the supervisor tree. Look into OTP testing strategies
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :score_server)
  end

  def init(_) do
    :ets.new(:score_table, [:set, :protected, :named_table])
    {:ok, nil}
  end

  def handle_call({:lookup, name}, _from, _) do
    value = case :ets.lookup(:score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    {:reply, value, nil}
  end

  def handle_call({:inc, name, reason}, _from, _) do
    scores = case :ets.lookup(:score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    new_score = elem(Enum.at(scores, -1), 0) + 1
    new_scores = [ {new_score, reason} | scores ]

    :ets.insert(:score_table, {name, new_scores})

    {:reply, total_score(new_scores), nil}
  end

  def handle_call({:dec, name, reason}, _from, _) do
    scores = case :ets.lookup(:score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    new_score = elem(Enum.at(scores, -1), 0) - 1
    new_scores = [ {new_score, reason} | scores ]

    :ets.insert(:score_table, {name, new_scores})

    {:reply, total_score(new_scores), nil}
  end

  def lookup(name) do
    GenServer.call(:score_server, {:lookup, String.capitalize(name)})
  end

  def inc(name, reason \\ "") do
    GenServer.call(:score_server, {:inc, String.capitalize(name), reason})
  end

  def dec(name, reason \\ "") do
    GenServer.call(:score_server, {:inc, String.capitalize(name), reason})
  end

  def scores do
    for key <- keys, into: %{}, do: {key, lookup(key)}
  end

  def html_scores do
    for key <- keys, into: "" do
      scores = lookup(key)
      output = "\n #{key} has #{total_score(scores)} points for the following reasons:\n"
      Enum.reduce(scores, output, fn {v, reason}, acc ->
        acc <> "\t * #{v} for #{reason} \n"
      end)
    end
  end

  def total_score(scores) do
    Enum.reduce(scores, 0, fn ({s, _r}, acc) -> s + acc end)
  end

  def keys do
    Enum.map(get_ets_keys_lazy(:score_table), &(&1))
  end

  def get_ets_keys_lazy(table_name) when is_atom(table_name) do
    eot = :"$end_of_table"

    Stream.resource(
      fn -> [] end,

      fn acc ->
        case acc do
          [] ->
            case :ets.first(table_name) do
              ^eot -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case :ets.next(table_name, acc) do
              ^eot -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end
end
