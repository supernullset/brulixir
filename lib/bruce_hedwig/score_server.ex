defmodule BruceHedwig.ScoreServer do
  require Logger

  use GenServer


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
    GenServer.call(:score_server, {:scores})
  end

  def html_scores do
    GenServer.call(:score_server, {:html_scores})
  end

  def total_score(scores) do
    Enum.reduce(scores, 0, fn ({s, _r}, acc) -> s + acc end)
  end

  def keys(score_table) do
    Enum.map(get_ets_keys_lazy(score_table), &(&1))
  end

  def get_ets_keys_lazy(table_name) when is_atom(table_name) do
    eot = :"$end_of_table"

    Stream.resource(
      fn -> [] end,

      fn acc ->
        case acc do
          [] ->
            case :dets.first(table_name) do
              ^eot -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case :dets.next(table_name, acc) do
              ^eot -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,

      fn _acc -> :ok end
    )
  end

  # TODO: This registration will fail *in test* when this application is
  # added to the supervisor tree. Look into OTP testing strategies
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :score_server)
  end

  def init(_) do
    {:ok, score_table} = :dets.open_file(:score_table, [type: :set])

    {:ok, score_table}
  end

  def handle_call({:lookup, name}, _from, score_table) do
    value = case :dets.lookup(score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    {:reply, value, score_table}
  end

  def handle_call({:inc, name, reason}, _from, score_table) do
    scores = case :dets.lookup(score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    new_score = elem(Enum.at(scores, -1), 0) + 1
    new_scores = [ {new_score, reason} | scores ]

    :dets.insert(score_table, {name, new_scores})

    {:reply, total_score(new_scores), score_table}
  end

  def handle_call({:dec, name, reason}, _from, score_table) do
    scores = case :dets.lookup(score_table, name) do
      [{^name, score_list}] -> score_list
      _ -> [{0, "existing"}]
    end

    new_score = elem(Enum.at(scores, -1), 0) - 1
    new_scores = [ {new_score, reason} | scores ]

    :dets.insert(score_table, {name, new_scores})

    {:reply, total_score(new_scores), score_table}
  end

  def handle_call({:scores}, _from, score_table) do
    s = for key <- keys(score_table), into: %{}, do: {key, lookup(key)}
    {:reply, s, score_table}
  end

  def handle_call({:html_scores}, _from, score_table) do
    formatted = for key <- keys(score_table), into: "" do
      scores = case :dets.lookup(score_table, key) do
                 [{^key, score_list}] -> score_list
                 _ -> [{0, "existing"}]
               end

      output = "\n #{key} has #{total_score(scores)} points for the following reasons:\n"
      Enum.reduce(scores, output, fn {v, reason}, acc ->
        acc <> "\t * #{v} for #{reason} \n"
      end)
    end

    {:reply, formatted, score_table}
  end

  def terminate(:shutdown, score_table) do
    :dets.close(score_table)
    {:noreply, score_table}
  end

  def handle_info(_msg, score_table) do
    {:noreply, score_table}
  end
end
