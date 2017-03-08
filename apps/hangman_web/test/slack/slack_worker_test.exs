defmodule HangmanWeb.SlackWorkerTest do
  use ExUnit.Case

  alias HangmanWeb.SlackWorker

  import HangmanWeb.Slack.Messages,
    only: [game_not_started_error: 0]

  @sq ":white_medium_small_square:"

  defp slack_data _ do
    slack =
      %Slack{user: %{id: "USERID", name: "user"},
        channel: %{id: "CHANNELID", name: "channel_name"},
        team: %{domain: "slackteam", id: "TEAMID"},
        response_url: "response_url"}
    {:ok, slack: slack}
  end
  
  defp fresh_game_session %{slack: slack} do
    id = slack.team.id <> slack.user.id 
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

  defmodule GameMock do
    def connect("TEAMID:USERID") do
      game =
        %{failures_remaining: 10, guessed: [], id: "TEAMID:USERID",
          puzzle: ["_", "_", "_", "_"], status: :new_game}
      {:ok, game}
    end

    # Correct guess
    def guess("TEAMID:USERID", "a") do
      game =
        %{failures_remaining: 9, guessed: ["a", "w"], id: "TEAMID:USERID",
          puzzle: ["_", "a", "_", "_"], status: :in_progress}
      {:ok, {:correct, game}}
    end

    # Incorrect guess
    def guess("TEAMID:USERID", "b") do
      game =
        %{failures_remaining: 8, guessed: ["b", "w"], id: "TEAMID:USERID",
          puzzle: ["_", "_", "_", "_"], status: :in_progress}
      {:ok, {:incorrect, game}}
    end

    # Final correct guess, wins game 
    def guess("TEAMID:USERID", "k") do
      game = 
        %{failures_remaining: 9, guessed: ["k", "l", "a", "t", "w"],
          id: "TEAMID:USERID", puzzle: ["t", "a", "l", "k"],
          secret: "talk", status: :won}
      {:ok, {:game_over, game}}
    end

    # Final incorrect guess, loses game
    def guess("TEAMID:USERID", "z") do
      game = 
        %{failures_remaining: 0,
          guessed: ["z", "y", "p", "q", "j", "w", "x", "f", "m", "o", "t"],
          id: "TEAMID:USERID", puzzle: ["t", "_", "_", "_"],
          secret: "talk", status: :lost}
      {:ok, {:game_over, game}}
    end

    # Already guessed letter
    def guess("TEAMID:USERID", "w") do
      {:error, {:already_guessed, "w"}}
    end
  end

  describe "play/1" do
    setup [:slack_data, :fresh_game_session]

    test "with invalid slack data, should return error" do
      slack = 
        %{user: %{"id" => "USERID", "name" => "user"},
          response_url: "response_url"}
      assert {:error, "invalid slack data"} = SlackWorker.play(slack)
    end

    test "with valid slack data, should dispatch to Genserver cast", context do
      assert :ok = SlackWorker.play(context.slack)
    end

    test "when a user has not started a game,
      should start new game session and send game details to response url.", %{slack: slack} do
      slack = Map.put(slack, :user, %{id: "NOSTART", name: "USER"})
      SlackWorker.handle_cast({:play, slack}, %{http: HttpMock, game: Hangman})   
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert %{
        attachments: [
          %{color: "#764FA5",
            fields: [
              %{title: "Puzzle", value: _},
              %{title: "Guessed Letters", value: "", short: true},
              %{title: "Failures Remaining", value: 10, short: true}]},
          %{pretext: "type /guess with a letter to solve the puzzle"}
        ]} = message 
    end
  
    test "when a user has already started a game, should send message with existing game session state", %{slack: slack} do
      SlackWorker.handle_cast({:play, slack}, %{http: HttpMock, game: Hangman})   
      assert_receive {:post, [url, message]} 

      SlackWorker.handle_cast({:play, slack}, %{http: HttpMock, game: Hangman})   
      assert_receive {:post, [^url, ^message]} 
    end
  end

  describe "guess/2" do
    setup [:slack_data, :fresh_game_session]

    test "with invalid slack data, should return error" do
      slack = 
        %{user: %{"id" => "USERID", "name" => "user"},
          response_url: "response_url"}
      assert {:error, "invalid slack data"} = SlackWorker.guess("a", slack)
    end

    test "with valid slack data, should dispatch to Genserver cast", context do
      assert :ok = SlackWorker.guess("a", context.slack)
    end

    test "when a game has not been started yet, should send error response message", %{slack: slack} do
      slack = Map.put(slack, :user, %{id: "ID_NOSTART", name: "user"})
      SlackWorker.handle_cast({:guess, "f", slack}, %{http: HttpMock, game: Hangman}) 
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == game_not_started_error()
    end

    test "with correct guess for started game, should send message with new game state and guess result", %{slack: slack} do
      SlackWorker.handle_cast({:guess, "a", slack}, %{http: HttpMock, game: GameMock})
      expected_msg =
        %{text: "*Correct!*",
          attachments: [
            %{color: "#36A64F",
              fields: [
                %{title: "Puzzle", value: @sq <> "a" <> @sq <> @sq},
                %{title: "Guessed Letters", value: "a, w", short: true},
                %{title: "Failures Remaining", value: 9, short: true}]},
            %{pretext: "type /guess with a letter to solve the puzzle"}]}
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == expected_msg
    end

    test "with incorrect guess for started game, should send message with new game state and guess result", %{slack: slack} do
      SlackWorker.handle_cast({:guess, "b", slack}, %{http: HttpMock, game: GameMock})
      expected_msg =
        %{text: "*Incorrect!*",
          attachments: [
            %{color: "#E02121",
              fields: [
                %{title: "Puzzle", value: @sq <> @sq <> @sq <> @sq},
                %{title: "Guessed Letters", value: "b, w", short: true},
                %{title: "Failures Remaining", value: 8, short: true}]},
            %{pretext: "type /guess with a letter to solve the puzzle"}]}
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == expected_msg
    end

    test "with a guess that loses the game, should send message with lost game state", %{slack: slack} do
      SlackWorker.handle_cast({:guess, "z", slack}, %{http: HttpMock, game: GameMock})
      expected_msg =
        %{attachments: [
            %{color: "#E02121",
              title: "Game over! You lose!",
              text: "Answer: talk"},
            %{fields: [
                %{title: "Puzzle",
                  value: "t" <> @sq <> @sq <> @sq},
                %{title: "Guessed Letters",
                  value: "z, y, p, q, j, w, x, f, m, o, t", short: true},
                %{title: "Failures Remaining",
                  value: 0, short: true}]},
            %{pretext: "type /playhangman to play again"}]}
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == expected_msg
    end

    test "with a guess that wins the game, should send message with won game state", %{slack: slack} do
      SlackWorker.handle_cast({:guess, "k", slack}, %{http: HttpMock, game: GameMock})
      expected_msg =
        %{attachments: [
            %{color: "#36A64F",
              title: "Game over! You win!",
              text: "Answer: talk"},
            %{fields: [
                %{title: "Puzzle",
                  value: "talk"},
                %{title: "Guessed Letters",
                  value: "k, l, a, t, w", short: true},
                %{title: "Failures Remaining",
                  value: 9, short: true}]},
            %{pretext: "type /playhangman to play again"}]}
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == expected_msg
    end

    test "with a letter that has already been guessed, should send error message", %{slack: slack} do
      SlackWorker.handle_cast({:guess, "w", slack}, %{http: HttpMock, game: GameMock})
      expected_msg =
        %{attachments: [
            %{color: "warning",
              text: "Oops! You already guessed the letter \"w\""}]}
      assert_receive {:post, [url, message]} 
      assert url == slack.response_url
      assert message == expected_msg
    end
  end
end
