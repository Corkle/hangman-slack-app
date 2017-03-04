defmodule HangmanWeb.Slack.CommandControllerTest do
  use HangmanWeb.ConnCase

  alias HangmanWeb.Slack.Messages

  defmodule MockWorker do
    def guess(char, slack) do
      send self(), {:guess, char, slack} 
    end
  end

  @slack_token Application.get_env(:hangman_web, :slack_message_token)

  @command_params %{
    "command" => "/slash_command", "text" => "hello",
    "team_id" => "TEAM_ID", "team_domain" => "TEAM",
    "channel_id" => "CH_ID", "channel_name" => "CHANNEL",
    "user_id" => "UID", "user_name" => "USER",
    "token" => "TOKEN", "response_url" => "RESP_URL"}

  defp mock_conn() do
    build_conn()
    |> put_private(:slack_action_worker, MockWorker)
  end

  describe "POST /playhangman" do
    test "with invalid slack token, should send 400 error response" do
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
      {:ok, expected_msg} = Poison.encode(Messages.welcome_msg())
      assert res.status == 200 
      assert res.resp_body == expected_msg
    end
  end

  describe "POST /guess" do
    test "with invalid slack token, should send 400 error response" do
      slack = Map.put(@command_params, "token", "INVALID")
      res = post(build_conn(), "/hangman/guess", slack)
      assert res.status == 400 
    end

    test "with blank text field, should return error slack message" do
      slack = @command_params
              |> Map.put("token", @slack_token)
              |> Map.put("command", "/guess")
              |> Map.put("text", "")
      {:ok, expected_msg} = Poison.encode(Messages.guess_param_error)
      res = post(build_conn(), "/hangman/guess", slack)
      assert res.status == 200 
      assert res.resp_body == expected_msg
    end

    test "with non-alpha char guess, should return error slack message" do
      slack = @command_params
              |> Map.put("token", @slack_token)
              |> Map.put("command", "/guess")
              |> Map.put("text", "*")
      {:ok, expected_msg} = Poison.encode(Messages.guess_param_error)
      res = post(build_conn(), "/hangman/guess", slack)
      assert res.status == 200 
      assert res.resp_body == expected_msg
    end

    test "with more than a single char guess, should return error slack message" do
      slack = @command_params
              |> Map.put("token", @slack_token)
              |> Map.put("command", "/guess")
              |> Map.put("text", "ab")
      {:ok, expected_msg} = Poison.encode(Messages.guess_param_error)
      res = post(build_conn(), "/hangman/guess", slack)
      assert res.status == 200 
      assert res.resp_body == expected_msg
    end

    test "with a single alpha char guess, should call worker's :guess fn" do
      slack = @command_params
              |> Map.put("token", @slack_token)
              |> Map.put("command", "/guess")
              |> Map.put("text", "x")
      res = post(mock_conn(), "/hangman/guess", slack)
      {:ok, expected_slack} = Slack.create(slack) 
      assert res.status == 200 
      assert_receive {:guess, "x", ^expected_slack}
    end
  end
end
