defmodule BruceHedwig.ScoreResponder do
  use Hedwig.Responder
  alias BruceHedwig.ScoreServer

  require Logger


  @usage """
  subject++ <reason> - Gives a thing a positive point
  """
  hear ~r/(?<subject>\A.+)\s*\+\+\s*for\s+(?<reason>.+\Z)/i, msg do
    current = ScoreServer.inc(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted! #{msg.matches["subject"]} has #{current} points"
  end

  @usage """
  subject-- <reason> - Gives a thing a negative point
  """
  hear ~r/(?<subject>\A.+)\s*\-\-\s*for\s+(?<reason>.+\Z)/i, msg do
    current = ScoreServer.dec(msg.matches["subject"], msg.matches["reason"])
    reply msg, "Noted! #{msg.matches["subject"]} has #{current} points"
  end

  @usage """
  list scores - Lists the current scores in a semi formatted way
  """
  respond ~r/(list scores)/i, msg do
    reply msg, ScoreServer.html_scores
  end
end
