defmodule HangmanWeb.Oauth.Slack.HTTPoison do
  @doc """
  Makes an external HTTPS `GET` call to Slack's `/api/oauth.access`
  endpoint to exchange a temporary OAuth access code for an API
  Access Token.

  See Slack's API documentation:
  https://api.slack.com/methods/oauth.access
  """
  @callback get_token(String.t) :: {:ok, String.t} | {:error, String.t} 
  def get_token(code) do
    res = HTTPoison.get("https://slack.com/api/oath.access")
    IO.inspect(res)
  end
end
