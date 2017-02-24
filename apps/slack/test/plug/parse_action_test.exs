defmodule Slack.Plug.ParseActionTest do
  use ExUnit.Case

  import Slack.PlugHelper
   
  alias Slack.Plug.ParseAction 

  describe "call/2" do
    test "when there is no payload in the request params,
      should assign nil to :slack_params" do
      conn = build_conn()
      res = ParseAction.call(conn, %{})
      assert %{slack_action: nil, slack_params: nil} = res.private 
    end

    test "when params.payload is not json format,
      plug should halt conn and return 400 response"
      
    test "when params.payload is valid json without expected slack action data,
      should assign :slack to conn with nil values for slack fields & nil :slack_token and :current_action"

    test "when params.payload is valid json with expected slack action data,
      should assign :slack as atom-keyed map for slack data and :current_action and :token with correct values."

    test "with missing actions field in payload, should assign nil to current_action"

    test "with nil value for actions field, should assign nil to current_action"

    test "with one action in actions field, should assign action {name, value} to current_action"

    test "with more than one action in actions field, should assign only first action's {name, value} to current_action"

    test "with action that does not have a value in actions field, should assign action name to current_action"
  end
end

