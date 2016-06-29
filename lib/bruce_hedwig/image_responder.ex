defmodule BruceHedwig.ImageResponder do
  use Hedwig.Responder
  require Logger

  @usage """
  Image me - Returns a image from a custom google search
  """
  hear ~r/image me (?<query>.+)/i, msg do
    query = msg.matches["query"]
    response = execute_query(query)
    reply msg, response
  end

  def execute_query(query) do
    cse_id = Application.get_env(:bruce_hedwig, :cse_id)
    google_api_key = Application.get_env(:bruce_hedwig, :google_api_key)
    base_url = "https://www.googleapis.com/customsearch/v1"

    query_payload = %{
      q: query,
      searchType: "image",
      safe: "high",
      cx: cse_id,
      key: google_api_key,
    }
    case HTTPoison.get(base_url, [], params: query_payload) do
      {:ok, %HTTPoison.Response{status_code: 403, body: body}} ->
        "Image quota exceeded :("
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body} = Poison.decode(body)
        if body["items"] do
          random(body["items"])["link"]
        else
          "Theres, uh, nothing here"
        end
      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code != 200->
        "Bad HTTP response (#{code}) :("
      {_,_} ->
        "Something has gone terribly wrong"
    end
  end
end
