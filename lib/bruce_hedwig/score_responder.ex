defmodule BruceHedwig.ScoreResponder do
  use Hedwig.Responder
  alias BruceHedwig.ScoreServer

  require Logger
  
  hear ~r/(?<subject>\A.+)\s*\+\+\s*for\s+(?<reason>.+\Z)/i, msg do
    ScoreServer.inc(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted!"
  end

  hear ~r/(?<subject>\A.+)\s*\-\-\s*for\s+(?<reason>.+\Z)/i, msg do
    ScoreServer.dec(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted!"
  end

  hear ~r/(what is the score?|tell me the score|list scores)/i, msg do
    reply msg, ScoreServer.scores
  end
end
