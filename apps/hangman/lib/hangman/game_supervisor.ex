defmodule Hangman.GameSupervisor do
  @moduledoc """
  Spawns and supervises `Hangman.GameSession` processes.
  """
  use Supervisor

  require Logger

  def start_link,
    do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    children = [
      worker(Hangman.GameSession, [], restart: :temporary)
    ]
    Logger.info("GameSupervisor Started!")
    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Spawns a GameSession as a supervised child.
  Returns `{:ok, pid}` if the server was spawned.

  If a GameSession of that id is already started, `pid`
  will be the existing process id.
  """
  def spawn_session(id),
    do: do_spawn_session(Supervisor.start_child(__MODULE__, [id]))

  defp do_spawn_session({:ok, pid}),
    do: {:ok, pid}
  defp do_spawn_session({:error, {:already_started, pid}}),
    do: {:ok, pid}
  defp do_spawn_session(_),
    do: {:error, :failed_start}
end
