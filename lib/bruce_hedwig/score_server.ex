defmodule BruceHedwig.ScoreServer do
  use GenServer

  require Logger

  # TODO: This registration will fail *in test* when this application is
  # added to the supervisor tree. Look into OTP testing strategies
  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def inc(name, reason \\ "") do
    GenServer.call(__MODULE__, {:inc, String.capitalize(name), reason})
  end

  def dec(name, reason \\ "") do
    GenServer.call(__MODULE__, {:dec, String.capitalize(name), reason})
  end

  def score(name) do
    GenServer.call(__MODULE__, {:score, String.capitalize(name)})
  end

  def raw_scores do
    GenServer.call(__MODULE__, {:scores})
  end

  def scores do
    scores = GenServer.call(__MODULE__, {:scores})
    "\n* " <> Enum.join(Enum.map(Map.keys(scores), fn k ->
      format_score(k, scores[k])
    end), "\n* ")
  end

  defp format_score(name, scores) do
    total = total_score(scores)
    score_by_reason = Enum.group_by(scores, fn {_s,r} -> r end)
    sub_scores = Enum.map(Map.keys(score_by_reason), fn reason ->
      if reason != "" do
        scores = score_by_reason[reason]
        "#{total_score(scores)} points for #{reason}"
      end
    end)

    if sub_scores != [nil] do
      "#{name} has #{total} points for the following reasons:#{Enum.join(sub_scores, "\n\t")}"
    else
      "#{name} has #{total} points"
    end
  end

  defp total_score(scores) do
    Enum.reduce(scores, 0, fn ({s, _r}, acc) -> s + acc end)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:inc, name, reason}, _from, names) do
    state = Map.get(names, name, [{0, ""}])
    new_score = elem(Enum.at(state, -1), 0) + 1
    new_scores = [ {new_score, reason} | state ]
    
    {:reply, total_score(new_scores), Map.put(names, name, new_scores)}
  end

  def handle_call({:dec, name, reason}, _from, names) do
    state = Map.get(names, name, [{0, ""}])
    new_score = elem(Enum.at(state, -1), 0) - 1
    new_scores = [ {new_score, reason} | state ]

    {:reply, total_score(new_scores), Map.put(names, name, new_scores)}
  end

  def handle_call({:score, name}, _from, names) do
    state = Map.get(names, name, [{0, ""}])
    {:reply, state, names}
  end

  def handle_call({:scores}, _from, names) do
    {:reply, names, names}
  end
end
