defmodule Slack.Plug.FetchSlackDataTest do
  use ExUnit.Case

  import Slack.PlugTestHelper
   
  alias Slack.Plug.FetchSlackData 

  test "with invalid Slack request params, should assign nil to :slack_data in conn.private" do
    conn = build_conn()
    res = FetchSlackData.call(conn, %{})
    assert %{slack_data: nil} = res.private 
  end

  describe "with action payload" do
    test "when payload is not json format, should assign nil to :slack_data in conn.private" do
      conn = build_conn(%{"payload" => 777})
      res = FetchSlackData.call(conn, %{})
      assert %{slack_data: nil} = res.private 
    end

    test "when payload is valid json without expected slack action,
      should assign nil to :slack_data in conn.private" do
      slack =
        %{team: %{id: "TEAM_ID", domain: "TEAM"},
          channel: %{id: "CH_ID", name: "CHANNEL"},
          user: %{id: "UID", name: "USER"},
          message_ts: "110000", token: "SLACKTOKEN", response_url: "url"}
      {:ok, json} = Poison.encode(slack) 
      conn = build_conn(%{"payload" => json}) 
      res = FetchSlackData.call(conn, %{})
      assert %{slack_data: nil} = res.private 
    end

    test "with nil value for actions field, should assign nil to :slack_data in conn.private"

    test "when payload is valid json with expected slack action,
      should assign private field :slack_data as Slack struct."

    test "with one action in actions field, should assign :action field in :slack_data as a map"

    test "with more than one action in actions field, should assign only first action in :action field in :slack_data"

    test "with action that does not have a value in actions field, should assign nil to :value in slack_data.action"
  end

  describe "with slash command params" do

  end
end
