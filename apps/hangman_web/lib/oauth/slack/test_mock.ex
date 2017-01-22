defmodule HangmanWeb.Oauth.Slack.TestMock do
  @behaviour HangmanWeb.Oauth.Slack.HTTPoison

  def get_token("VALID_CODE"),
    do: {:ok, "SLACK_TOKEN"}
  
  def get_token("INVALID_CODE"),
    do: {:error, "INVALID_ACCESS_TOKEN"}

  def get_token(_),
    do: {:error, "Unknown error"}
end
