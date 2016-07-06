defmodule BruceHedwig.EchoTest do
  use Hedwig.RobotCase

  alias Hedwig.Responder

  test "response_pattern" do
    robot = %Hedwig.Robot{name: "bruce", aka: nil}

    assert Responder.respond_pattern(~r/ping/i, robot) ==
      ~r/^\s*[@]?bruce[:,]?\s*(?:ping)/i
  end
end
