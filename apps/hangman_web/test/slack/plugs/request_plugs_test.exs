defmodule HangmanWeb.Slack.RequestPlugsTest do
  use HangmanWeb.ConnCase 
  import HangmanWeb.Slack.RequestPlugs 

  describe "parse_command_data/2" do
    test "when conn has empty params,
      should return conn with assigns.command with nil for all expected Slack fields" do
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
      should assign :slack to conn with nil values for slack fields & nil :slack_token and :current_action" do
      {:ok, json} = Poison.encode(%{name: "John"})
      params = %{"payload" => json}
      conn = build_conn(:post, "/hangman/message_actions", params)
             |> parse_action_payload(nil)
      expected = 
        %{slack:
          %{actions: nil, callback_id: nil, team: nil,
            channel: nil, user: nil, action_ts: nil,
            message_ts: nil, attachment_id: nil, token: nil,
            original_message: nil, response_url: nil},
          slack_token: nil,
          current_action: nil}
      assert conn.assigns == expected
    end

    test "when params.payload is valid json with expected slack action data,
      should assign :slack as atom-keyed map for slack data and :current_action and :token with correct values." do
      params = %{"actions" => [%{"name" => "SLACK_ACTION"}], "callback_id" => "CALLBACK_ID",
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "action_ts" => "ACTION_TS",
                 "message_ts" => "MESSAGE_TS", "attachment_id" => "ATTACHMENT_ID",
                 "token" => "SLACK_TOKEN", "original_message" => "ORIGINAL_MESSAGE",
                 "response_url" => "RESPONSE_URL"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected = 
        %{slack: 
          %{actions: [%{"name" => "SLACK_ACTION"}], callback_id: "CALLBACK_ID",
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: "ACTION_TS",
            message_ts: "MESSAGE_TS", attachment_id: "ATTACHMENT_ID",
            token: "SLACK_TOKEN", original_message: "ORIGINAL_MESSAGE",
            response_url: "RESPONSE_URL"},
          slack_token: "SLACK_TOKEN",
          current_action: "SLACK_ACTION"}
      assert conn.assigns == expected
    end

    test "with missing actions field in payload, should assign nil to current_action" do
      params = %{
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "token" => "SLACK_TOKEN"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected =
        %{slack: 
          %{actions: nil, callback_id: nil,
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: nil,
            message_ts: nil, attachment_id: nil,
            token: "SLACK_TOKEN", original_message: nil,
            response_url: nil},
          slack_token: "SLACK_TOKEN",
          current_action: nil}
      assert conn.assigns == expected
    end

    test "with nil value for actions field, should assign nil to current_action" do
      params = %{"actions" => nil,
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "token" => "SLACK_TOKEN"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected =
        %{slack: 
          %{actions: nil, callback_id: nil,
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: nil,
            message_ts: nil, attachment_id: nil,
            token: "SLACK_TOKEN", original_message: nil,
            response_url: nil},
          slack_token: "SLACK_TOKEN",
          current_action: nil}
      assert conn.assigns == expected
    end

    test "with one action in actions field, should assign action {name, value} to current_action" do
      params = %{"actions" => [%{"name" => "ACTION", "value" => 99}], 
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "token" => "SLACK_TOKEN"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected =
        %{slack: 
          %{actions: [%{"name" => "ACTION", "value" => 99}], callback_id: nil,
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: nil,
            message_ts: nil, attachment_id: nil,
            token: "SLACK_TOKEN", original_message: nil,
            response_url: nil},
          slack_token: "SLACK_TOKEN",
          current_action: {"ACTION", 99}}
      assert conn.assigns == expected
    end

    test "with more than one action in actions field, should assign only first action's {name, value} to current_action" do
      params = %{"actions" => [%{"name" => "ACTION_A", "value" => 7}, %{"name" => "ACTION_B", "value" => 0}], 
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "token" => "SLACK_TOKEN"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected =
        %{slack: 
          %{actions: [%{"name" => "ACTION_A", "value" => 7}, %{"name" => "ACTION_B", "value" => 0}],
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: nil,
            message_ts: nil, attachment_id: nil,
            token: "SLACK_TOKEN", original_message: nil,
            callback_id: nil, response_url: nil},
          slack_token: "SLACK_TOKEN",
          current_action: {"ACTION_A", 7}}
      assert conn.assigns == expected
    end

    test "with action that does not have a value in actions field, should assign action name to current_action" do
      params = %{"actions" => [%{"name" => "ACTION"}], 
                 "team" => "SLACK_TEAM", "channel" => "SLACK_CHANNEL",
                 "user" => "SLACK_USER", "token" => "SLACK_TOKEN"}
      {:ok, json} = Poison.encode(params)
      conn = build_conn(:post, "/hangman/message_actions", %{"payload" => json})
             |> parse_action_payload(nil)
      expected =
        %{slack: 
          %{actions: [%{"name" => "ACTION"}], callback_id: nil,
            team: "SLACK_TEAM", channel: "SLACK_CHANNEL",
            user: "SLACK_USER", action_ts: nil,
            message_ts: nil, attachment_id: nil,
            token: "SLACK_TOKEN", original_message: nil,
            response_url: nil},
          slack_token: "SLACK_TOKEN",
          current_action: "ACTION"}
      assert conn.assigns == expected
    end
  end

  describe "verify_slack_token/2" do
    test "when no Slack token is provided as second argument,
      should raise error" do
      conn = build_conn()
      assert_raise ArgumentError, fn -> 
        verify_slack_token(conn, nil)
      end
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
