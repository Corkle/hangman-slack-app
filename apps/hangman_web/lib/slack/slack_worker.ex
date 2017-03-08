defmodule HangmanWeb.SlackWorker do
  @moduledoc """
  Handles game actions from Slack requests and responds to the
  message after the initial HTTP response has already been sent.
  """
  use GenServer

  require Logger

  import HangmanWeb.Slack.Messages,
    only: [game_not_started_error: 0, already_guessed_error: 1]

  @http Application.get_env(:hangman_web, :slack_http)
  @game Hangman

  def start_link(name),
    do: GenServer.start_link(__MODULE__, nil, [name: name])

  def init(_),
    do: {:ok, %{http: @http, game: @game}}

  def play(slack),
    do: try_cast(:play, slack)

  def guess(char, slack),
    do: try_cast(:guess, char, slack)

  def handle_cast({:play, slack}, state) do
    with {:ok, id} <- get_game_id(slack),
         {:ok, game} <- get_game_session(state, id) do
           send_json(state, slack.response_url, game_message(:play, game))
    else
      _ -> Logger.error("bad cast", [slack: slack])
    end
    {:noreply, state}
  end

  def handle_cast({:guess, char, slack}, %{game: game} = state) do
    with {:ok, id} <- get_game_id(slack),
         {:ok, game} <- game.guess(id, char) do
           send_json(state, slack.response_url, game_message(:guess, game))
    else
      {:error, error} -> send_error_resp(error, state, slack)
      _ -> send_error_resp(:error, state, slack)
    end
    {:noreply, state}
  end

  defp game_message(:play, game) do
    %{attachments: [
      %{color: "#764FA5",
        fields: game_message_fields(game)},
      %{pretext: "type /guess with a letter to solve the puzzle"}
    ]}
  end

  defp game_message(:guess, {:correct, game}) do
    %{text: "*Correct!*",
      attachments: [
      %{color: "#36A64F",
        fields: game_message_fields(game)},
      %{pretext: "type /guess with a letter to solve the puzzle"}]}
  end

  defp game_message(:guess, {:incorrect, game}) do
    %{text: "*Incorrect!*",
      attachments: [
      %{color: "#E02121",
        fields: game_message_fields(game)},
      %{pretext: "type /guess with a letter to solve the puzzle"}]}
  end

  defp game_message(:guess, {:game_over, game}) do
    game_over_message(game)
  end

  defp game_message_fields(game) do
    [%{title: "Puzzle",
       value: format_puzzle(game.puzzle)},
     %{title: "Guessed Letters",
       value: format_guessed(game.guessed), short: true},
     %{title: "Failures Remaining",
       value: game.failures_remaining, short: true}]
  end

  defp game_over_message(%{status: :lost} = game) do
    %{attachments: [
        %{color: "#E02121",
          title: "Game over! You lose!",
          text: "Answer: #{game.secret}"},
        %{fields: game_message_fields(game)},
        %{pretext: "type /playhangman to play again"}]}
  end

  defp game_over_message(%{status: :won} = game) do
    %{attachments: [
        %{color: "#36A64F",
          title: "Game over! You win!",
          text: "Answer: #{game.secret}"},
        %{fields: game_message_fields(game)},
        %{pretext: "type /playhangman to play again"}]}
  end

  defp format_puzzle(puzzle) do
    puzzle
    |> Enum.map(&format_puzzle_char/1)
    |> Enum.join
  end

  defp format_puzzle_char(" "), do: "\t"
  defp format_puzzle_char("_"), do: ":white_medium_small_square:"
  defp format_puzzle_char(val), do: val

  defp format_guessed([]), do: ""
  defp format_guessed(list), do: Enum.join(list, ", ")

  defp send_json(%{http: http}, url, body),
    do: http.post_json(url, body)

  defp send_error_resp(:not_spawned, %{http: http}, %{response_url: url}),
    do: http.post_json(url, game_not_started_error())
  defp send_error_resp({:already_guessed, char}, %{http: http}, slack),
    do: http.post_json(slack.response_url, already_guessed_error(char))
  defp send_error_resp(_, %{http: http}, %{response_url: url}),
    do: http.post_json(url, %{text: "Oops! That request could not be handled."})

  defp get_game_id(%{user: %{id: uid}, team: %{id: team}}),
    do: {:ok, team <> ":" <>  uid}
  defp get_game_id(_),
    do: {:error, "invalid slack data"}

  defp get_game_session(%{game: game}, id),
    do: game.connect(id)
  defp get_game_session(_, _),
    do: {:error, :unknown_game_module}

  defp try_cast(action, %Slack{} = slack),
    do: GenServer.cast(__MODULE__, {action, slack})
  defp try_cast(_, _),
    do: {:error, "invalid slack data"}
  defp try_cast(action, arg, %Slack{} = slack),
    do: GenServer.cast(__MODULE__, {action, arg, slack})
  defp try_cast(_, _, _),
    do: {:error, "invalid slack data"}
end
