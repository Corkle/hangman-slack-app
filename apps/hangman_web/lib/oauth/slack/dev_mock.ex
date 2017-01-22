defmodule HangmanWeb.Oauth.Slack.DevMock do
  @behaviour HangmanWeb.Oauth.Slack.HTTPoison 

  def get_token(code) do
    IO.inspect(code)
    url = "https://slack.com/api/oauth.access" 
    headers = [{"Content-Type", "application/json; charset=utf-8"}]
    body = Poison.encode!(%{
      client_id: Application.get_env(:hangman_web, :slack_app_client_id),
      client_secret: Application.get_env(:hangman_web, :slack_app_secret)
    })
    body = Poison.encode!(%{
      client_id: "19427839078.126988800178",
      client_secret: nil,
      code: code
    })
    IO.inspect(body)
    
    res = HTTPoison.post(url, body, headers, [])
    IO.inspect(res)
  end
end

