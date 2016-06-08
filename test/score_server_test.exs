defmodule BruceHedwig.ScoreServerTest do
  alias BruceHedwig.ScoreServer

  use ExUnit.Case, async: true

  setup do
    {:ok, server} = ScoreServer.start_link
    {:ok, server: server}
  end

  test "increments properly", %{server: _server} do
    value = ScoreServer.inc("bruce")
    assert value == 1
    value = ScoreServer.inc("bruce", "reasons")
    assert value == 2
  end

  test "decrements properly", %{server: _server} do
    value = ScoreServer.dec("bruce")
    assert value == -1
    value = ScoreServer.dec("bruce", "reasons")
    assert value == -2
  end

  test "returns score for a particular user", %{server: _server} do
    ScoreServer.inc("bruce")
    ScoreServer.inc("bruce", "reasons")
    score = ScoreServer.score("bruce")

    assert score == [{1, "reasons"}, {1, ""}, {0, ""}]
  end

  test "returns raw scores for all users", %{server: _server} do
    ScoreServer.inc("bruce")
    ScoreServer.inc("bob", "being cool")
    scores = ScoreServer.raw_scores

    assert scores == %{"Bruce" => [{1, ""}, {0, ""}],
                       "Bob"   => [{1, "being cool"}, {0, ""}]}
  end

  test "returns formatted scores properly", %{server: _server} do
    ScoreServer.inc("bruce")
    ScoreServer.inc("bob", "being cool")
    scores = ScoreServer.scores

    assert scores =~ "* Bob has 1 points for the following reasons:\n\t1 points for being cool"
    assert scores =~ "* Bruce has 1 points"
  end
end
