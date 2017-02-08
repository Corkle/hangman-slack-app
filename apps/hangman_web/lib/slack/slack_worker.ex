defmodule HangmanWeb.SlackWorker do
  @moduledoc """
  Handles dispatching game actions and responding
  to the message after the initial response has
  already been sent.
  """
  use GenServer

  require Logger

  alias HangmanGame.GameSession

  @http Application.get_env(:hangman_web, :slack_http)

  def start_link(name),
    do: GenServer.start_link(__MODULE__, nil, [name: name])

  def dispatch(:play, slack),
    do: try_cast(:play, is_slack(slack)) 

  def dispatch(action, slack) do
    IO.puts("WORKER.DISPATCH")
  end

  def init(_),
    do: {:ok, %{http: @http}}

  def handle_cast({:play, slack}, state) do
    with {:ok, id} <- get_id(slack),
         {:ok, game} <- GameSession.connect(id) do
           state.http.post_json(slack.response_url, game_message(:play, game))
    else
      _ -> Logger.error("bad cast", [slack: slack]) 
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

  defp game_message_fields(game) do
    [%{title: "Puzzle", value: format_puzzle(game.puzzle)},
     %{title: "Guessed Letters", value: "", short: true},
     %{title: "Failures Remaining", value: game.failures_remaining, short: true}]
  end

  defp format_puzzle(puzzle) do
    Enum.map(puzzle, fn x ->
      case x do
        " " -> "\t"
        "_" -> ":white_medium_small_square:"
        val -> val
      end
    end)
    |> Enum.join
  end

  def get_id(%{user: %{"id" => uid}, team: %{"id" => team}}),
    do: {:ok, team <> ":" <>  uid}
  def get_id(_),
    do: {:error, "invalid slack data"}

  defp is_slack(%{user: _, team: _, response_url: _} = slack),
    do: {:ok, slack} 
  defp is_slack(_),
    do: {:error, "invalid slack data"}

  defp try_cast(action, {:ok, slack}),
    do: GenServer.cast(__MODULE__, {action, slack}) 
  defp try_cast(_, _),
    do: {:error, "invalid slack data"}
end

