defmodule HangmanWeb.Oauth.Slack.HTTPTest do
  use HangmanWeb.ConnCase 
  alias HangmanWeb.Oauth.Slack.HTTP, as: SlackHTTP

  @moduletag :slack_api
  # slack_api tagged tests are excluded by default

  #TODO: make client_secret env variable available for test
  test "" do
    res = SlackHTTP.get_token("")
    assert res == false
  end
end

