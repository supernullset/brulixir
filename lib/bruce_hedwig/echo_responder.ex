defmodule BruceHedwig.EchoResponder do
  use Hedwig.Responder


  hear ~r/ping/i, msg do
    reply msg, "pong"
  end
end
