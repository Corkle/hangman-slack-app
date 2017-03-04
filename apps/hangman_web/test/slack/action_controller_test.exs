defmodule HangmanWeb.Slack.ActionControllerTest do
  use HangmanWeb.ConnCase

  defmodule MockWorker do
    def play(slack) do
      send self(), {:play, slack} 
    end
  end

  @slack_token Application.get_env(:hangman_web, :slack_message_token)

  @action_params %{
    "actions" => [%{"name" => "action", "value" => "val"}],
    "team" => %{"id" => "TEAM_ID", "domain" => "TEAM"},
    "channel" => %{"id" => "CH_ID", "name" => "CHANNEL"},
    "user" => %{"id" => "UID", "name" => "USER"},
    "action_ts" => "00000000", "message_ts" => "1111111",
    "attachment_id" => "ATTACH_ID", "token" => "TOKEN",
    "callback_id" => "123", "original_message" => %{},
    "response_url" => "RESP_URL"}

  defp mock_conn() do
    build_conn()
    |> put_private(:slack_action_worker, MockWorker)
  end

  defp post_action(conn, slack_params) do
    {:ok, payload} = Poison.encode(slack_params)
    post(conn, "/hangman/message_actions", %{"payload" => payload})
  end

  describe "handle play_game action route" do
    test "with invalid slack token, should send 400 error response" do
      slack =
        @action_params
        |> Map.put("token", "INVALID")
        |> Map.put("actions", [%{"name" => "play_game", "value" => ""}])
      res = post_action(mock_conn(), slack)
      assert res.status == 400 
    end

    test "with valid slack token, should send 200 response and call worker's :play fn" do
      slack = 
        @action_params
        |> Map.put("token", @slack_token)
        |> Map.put("actions", [%{"name" => "play_game", "value" => ""}])
      res = post_action(mock_conn(), slack)
      {:ok, expected_slack} = Slack.create(slack) 
      assert res.status == 200 
      assert_receive {:play, ^expected_slack}
    end
  end
end
