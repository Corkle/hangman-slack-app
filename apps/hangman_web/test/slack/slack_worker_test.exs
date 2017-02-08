defmodule HangmanWeb.SlackWorkerTest do
  use ExUnit.Case
  alias HangmanWeb.SlackWorker

  defp slack_data _ do
    slack =
      %{user: %{"id" => "USERID", "name" => "user"},
        channel: %{"id" => "CHANNELID", "name" => "channel_name"},
        team: %{"domain" => "slackteam", "id" => "TEAMID"},
        response_url: "response_url"}
    {:ok, slack: slack}
  end
  
  defp fresh_game_session %{slack: slack} do
    id = slack.team["id"] <> slack.user["id"] 
    on_exit fn ->
      kill_proc(GenServer.whereis({:global, {:session, id}}))
    end
    {:ok, session_id: id}
  end
  
  defp kill_proc(nil), do: :ok
  defp kill_proc(pid), do: GenServer.stop(pid) 

  defmodule HttpMock do  
    @behaviour HangmanWeb.Slack.HTTP
    def post_json(url, body) do
      send self(), {:post, [url, body]} 
    end
  end

  describe "dispatch(:play, slack)" do
    setup [:slack_data, :fresh_game_session]

    test "with invalid slack data, should return error" do
      slack = 
        %{user: %{"id" => "USERID", "name" => "user"},
          response_url: "response_url"}
      assert {:error, "invalid slack data"} = SlackWorker.dispatch(:play, slack)
    end

    test "with valid slack data, should dispatch to Genserver cast", context do
      assert :ok = SlackWorker.dispatch(:play, context.slack)
    end

    test "when a user has not started a game,
      should start new game session and send game details to response url.", %{slack: slack} do
      SlackWorker.handle_cast({:play, slack}, %{http: HttpMock})   
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert %{attachments: _} = message 
    end

  end
end
