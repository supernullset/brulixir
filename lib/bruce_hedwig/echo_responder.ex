defmodule BruceHedwig.EchoResponder do
  use Hedwig.Responder

  @usage """
  ping - Responds to a user who says ping with a pong
  """
  respond ~r/ping$/i, %{robot: robot} = msg do
    reply msg, "pong"
  end
end
