defmodule HangmanWeb.Slack.CommandControllerTest do
  use HangmanWeb.ConnCase

  @slack_token Application.get_env(:hangman_web, :slack_message_token)

  @command_params %{
    "command" => "/slash_command", "text" => "hello",
    "team_id" => "TEAM_ID", "team_domain" => "TEAM",
    "channel_id" => "CH_ID", "channel_name" => "CHANNEL",
    "user_id" => "UID", "user_name" => "USER",
    "token" => "TOKEN", "response_url" => "RESP_URL"}

  describe "POST /playhangman" do
    test "invalid slack token, should send 400 error response" do
      slack = Map.put(@command_params, "token", "INVALID")
      res = post(build_conn(), "/hangman/play", slack)
      assert res.status == 400 
    end

    test "with valid slack token, should send welcome message with 200 response" do
      slack =
        @command_params
        |> Map.put("token", @slack_token)
        |> Map.put("command", "/playhangman")
      res = post(build_conn(), "/hangman/play", slack)
      {:ok, expected_msg} = Poison.encode(HangmanWeb.Slack.ActionButtons.welcome_msg())
      assert res.status == 200 
      assert res.resp_body == expected_msg
    end
  end

end
