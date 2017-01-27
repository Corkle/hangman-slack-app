defmodule HangmanWeb.SlackPlugsTest do
  use HangmanWeb.ConnCase 
  import HangmanWeb.SlackPlugs 

  describe "parse_command_data/2" do
    test "when conn has empty params,
      should return conn with assigns.command will nil for all expected Slack fields" do
      conn = build_conn() |> parse_command_data(nil) 
      expected =
        %{command:
          %{channel_id: nil, channel_name: nil,
            command: nil, response_url: nil,
            team_domain: nil, team_id: nil,
            token: nil, text: nil, user_id: nil,
            user_name: nil},
          slack_token: nil}
      assert conn.assigns == expected
    end

    test "when conn has expected slack data,
      should assign :token value and :command as an atom-keyed map for slack data." do
      params =
        %{"channel_id" => "CHANNEL_ID", "channel_name" => "CHANNEL_NAME",
          "command" => "SLACK_COMMAND", "response_url" => "RESPONSE_URL",
          "team_domain" => "TEAM_DOMAIN", "team_id" => "TEAM_ID",
          "text" => "SLACK_TEXT", "token" => "SLACK_TOKEN",
          "user_id" => "USER_ID", "user_name" => "USER_NAME"}
      expected =
        %{command:
          %{channel_id: "CHANNEL_ID", channel_name: "CHANNEL_NAME",
            command: "SLACK_COMMAND", response_url: "RESPONSE_URL",
            team_domain: "TEAM_DOMAIN", team_id: "TEAM_ID",
            text: "SLACK_TEXT", token: "SLACK_TOKEN",
            user_id: "USER_ID", user_name: "USER_NAME"},
          slack_token: "SLACK_TOKEN"}
      conn = build_conn(:post, "/hangman/play", params) |> parse_command_data(nil)
      assert conn.assigns == expected 
    end
  end

  describe "parse_action_payload/2" do
    test "when there is no payload in the request params,
      plug should halt conn and return 400 response" do
      conn = build_conn() |> parse_action_payload(nil)
      assert conn.status == 400
      assert conn.halted == true
    end

    test "when params.payload is not json format,
      plug should halt conn and return 400 response" do
      params = %{"payload" => "Just a string"}
      conn = build_conn(:post, "/hangman/message_actions", params)
             |> parse_action_payload(nil)
      assert conn.status == 400
      assert conn.halted == true
    end

    test "when params.payload is valid json without expected slack action data,
      should assign :action to conn with nil values for slack fields." do
      {:ok, json} = Poison.encode(%{name: "John"})
      params = %{"payload" => json}
      conn = build_conn(:post, "/hangman/message_actions", params)
             |> parse_action_payload(nil)
      expected = 
        %{action:
          %{actions: nil, callback_id: nil, team: nil,
            channel: nil, user: nil, action_ts: nil,
            message_ts: nil, attachment_id: nil, token: nil,
            original_message: nil, response_url: nil},
          slack_token: nil}
      assert conn.assigns == expected
    end

    test "when params.payload is valid json with expected slack action data,
      should assign :token value and :action as atom-keyed map for slack data." do
      params = %{"actions" => "SLACK_ACTION", "callback_id" => "CALLBACK_ID",
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "action_ts" => "ACTION_TS",
                 "message_ts" => "MESSAGE_TS", "attachment_id" => "ATTACHMENT_ID",
                 "token" => "SLACK_TOKEN", "original_message" => "ORIGINAL_MESSAGE",
                 "response_url" => "RESPONSE_URL"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected = 
        %{action: 
          %{actions: "SLACK_ACTION", callback_id: "CALLBACK_ID",
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: "ACTION_TS",
            message_ts: "MESSAGE_TS", attachment_id: "ATTACHMENT_ID",
            token: "SLACK_TOKEN", original_message: "ORIGINAL_MESSAGE",
            response_url: "RESPONSE_URL"},
          slack_token: "SLACK_TOKEN"}
      assert conn.assigns == expected
    end
  end

  describe "verify_slack_token/2" do
    test "when no Slack token is provided as second argument,
      should return 400 response and halt pipeline" do
      conn = build_conn() |> verify_slack_token(nil)
      assert conn.status == 400
      assert conn.halted == true
    end

    test "when assigns.slack_token does not match the provided token argument,
      should return 400 response and halt pipeline" do
      conn = build_conn() |> assign(:slack_token, "INVALID_TOKEN")
             |> verify_slack_token("TOKEN_ARGUMENT") 
      assert conn.status == 400
      assert conn.halted == true
    end
    
    test "when assigns.slack_token matches the provided token argument,
      should return conn unchanged." do
      conn = build_conn() |> assign(:slack_token, "VALID_TOKEN")
      assert ^conn = verify_slack_token(conn, "VALID_TOKEN") 
    end
  end
end
