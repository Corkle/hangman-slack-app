defmodule HangmanWeb.Slack.HTTPMock do
  @behaviour HangmanWeb.Slack.HTTP

  def post_json(url, body),
    do: handle_result(url, Poison.encode(body))

  defp handle_result(url, {:ok, json}),
    do: {:ok, {url, Poison.decode!(json)}}
  defp handle_result(url, _),
    do: {:error, "invalid json"}
end

