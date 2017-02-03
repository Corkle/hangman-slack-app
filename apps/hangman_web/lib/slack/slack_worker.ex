defmodule HangmanWeb.SlackWorker do
  @moduledoc """
  Handles dispatching game actions and responding
  to the message after the initial response has
  already been sent.
  """
  use GenServer
  alias HangmanGame.GameSession

  def start_link(name),
    do: GenServer.start_link(__MODULE__, nil, [name: name])

  def play(msg),
    do: GenServer.cast(__MODULE__, {:play, msg}) 

  def dispatch(action, slack) do
    IO.puts("WORKER.DISPATCH")
  end

  def init(state),
    do: {:ok, state}

  def handle_cast({:play, msg}, _) do
    IO.inspect msg
    id = msg.user["id"]
    {:ok, game} = GameSession.connect(id)
    IO.inspect(game)
    IO.inspect HTTPoison.post(msg.response_url, Poison.encode!(%{text: "Game ready!"}), [{"Content-Type", "application/json"}])
    {:noreply, nil}
  end
end

