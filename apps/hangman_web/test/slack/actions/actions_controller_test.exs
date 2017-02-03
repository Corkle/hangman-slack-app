defmodule HangmanWeb.Slack.ActionsControllerTest do
  use HangmanWeb.ConnCase

  defmodule MockWorker do
    def dispatch(action, slack) do
      send self(), {action, slack} 
    end
  end

  defp mock_conn() do
    build_conn()
    |> put_private(:slack_action_worker, MockWorker)
  end

  defp post_action(conn, slack_params) do
    {:ok, payload} = Poison.encode(slack_params)
    post(conn, "/hangman/message_actions", %{"payload" => payload})
  end

  defp slack_data(action) do
    %{action_ts: "1485000000.122000", actions: [action],
      attachment_id: "1", callback_id: "cb_0",
      channel: %{"id" => "CHANNEL", "name" => "channel_name"},
      message_ts: "1485000000.122000", original_message: nil,
      response_url: "response_url",
      team: %{"domain" => "slackteam", "id" => "TEAMID"},
      token: "SLACK_MSG_TOKEN", user: %{"id" => "USERID", "name" => "user"}}
  end

  describe "POST /hangman/message_actions" do
    test "with invalid slack token, should send 400 error response" do
      slack = %{"token" => "INVALID", "actions" => []}
      res = post_action(mock_conn(), slack)
      assert res.status == 400 
    end

    test "with valid slack token, should send 200 response" do
      slack = %{"token" => "SLACK_MSG_TOKEN", "actions" => []}
      res = post_action(mock_conn(), slack)
      assert res.status == 200 
    end
  end

  describe "dispatch/3" do
    test "with nil action, should return 200 response" do
      slack = %{actions: nil, token: "SLACK_MSG_TOKEN"}
      res = post_action(mock_conn(), slack) 
      assert res.status == 200
    end
  end

  describe "dispatch/3 | play_game" do
    test "should return a 200 response and call SlackWork.dispatch" do
      slack = slack_data(%{"name" => "play_game"})
      res = post_action(mock_conn(), slack)
      {:ok, expected_body} = Poison.encode(%{text: "Please wait..."})
      assert res.status == 200
      assert res.resp_body == expected_body
      assert_receive {:play, ^slack}
    end
  end
end
