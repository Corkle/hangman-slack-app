defmodule HangmanWeb.SlackWorker do
  @moduledoc """
  Handles game actions from Slack requests and responds to the
  message after the initial HTTP response has already been sent.
  """
  use GenServer

  require Logger

  @http Application.get_env(:hangman_web, :slack_http)

  def start_link(name),
    do: GenServer.start_link(__MODULE__, nil, [name: name])

  def init(_),
    do: {:ok, %{http: @http}}

  def play(slack),
    do: try_cast(:play, slack)

  def guess(char, slack),
    do: try_cast(:guess, char, slack)
    
  def handle_cast({:play, slack}, state) do
    with {:ok, id} <- get_id(slack),
         {:ok, game} <- Hangman.connect(id) do
           send_json(state, slack.response_url, game_message(:play, game))
    else
      _ -> Logger.error("bad cast", [slack: slack])
    end
    {:noreply, state}
  end

  def handle_cast({:guess, char, slack}, state) do
    :todo
  end

  defp game_message(:play, game) do
    %{attachments: [
        %{color: "#764FA5",
          fields: game_message_fields(game)},
        %{pretext: "type /guess with a letter to solve the puzzle"}
    ]}
  end

  defp game_message_fields(game) do
    [%{title: "Puzzle", value: format_puzzle(game.puzzle)},
     %{title: "Guessed Letters", value: "", short: true},
     %{title: "Failures Remaining", value: game.failures_remaining, short: true}]
  end

  defp format_puzzle(puzzle) do
    puzzle
    |> Enum.map(&format_puzzle_char/1)
    |> Enum.join
  end

  defp format_puzzle_char(" "), do: "\t"
  defp format_puzzle_char("_"), do: ":white_medium_small_square:"
  defp format_puzzle_char(val), do: val

  defp send_json(%{http: http}, url, body),
    do: http.post_json(url, body)

  defp get_id(%{user: %{id: uid}, team: %{id: team}}),
    do: {:ok, team <> ":" <>  uid}
  defp get_id(_),
    do: {:error, "invalid slack data"}

  defp try_cast(action, %Slack{} = slack),
    do: GenServer.cast(__MODULE__, {action, slack})
  defp try_cast(_, _),
    do: {:error, "invalid slack data"}
  defp try_cast(action, arg, %Slack{} = slack),
    do: GenServer.cast(__MODULE__, {action, arg, slack})
  defp try_cast(_, _, _),
    do: {:error, "invalid slack data"}
end
