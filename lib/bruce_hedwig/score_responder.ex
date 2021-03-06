defmodule BruceHedwig.ScoreResponder do
  use Hedwig.Responder
  alias BruceHedwig.ScoreServer

  require Logger


  @usage """
  hedwig help - Gives a thing a positive point
  """
  hear ~r/(?<subject>\A.+)\s*\+\+\s*for\s+(?<reason>.+\Z)/i, msg do
    ScoreServer.inc(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted!"
  end

  @usage """
  hedwig help - Gives a thing a negative point
  """
  hear ~r/(?<subject>\A.+)\s*\-\-\s*for\s+(?<reason>.+\Z)/i, msg do
    ScoreServer.dec(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted!"
  end

  @usage """
  hedwig help - Lists the current scores in a semi formatted way
  """
  hear ~r/(what is the score?|tell me the score|list scores)/i, msg do
    reply msg, ScoreServer.scores
  end
end
