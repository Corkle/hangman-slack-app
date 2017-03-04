defmodule Hangman do
  @moduledoc """
  ## Usage

  ```
  iex> Hangman.connect("MY_ID")
  {:ok,
     %{failures_remaining: 10, guessed: [], id: "MY_ID",
          puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "_",
                       "_", "_", "_", "_", "!"], status: :new_game}}
  iex> Hangman.guess("MY_ID", "e")
  {:ok,
     {:correct,
         %{failures_remaining: 10, guessed: ["e"], id: "MY_ID",
               puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "e",
                             "_", "_", "e", "_", "!"], status: :in_progress}}}
  iex> Hangman.guess("MY_ID", "x")
  {:ok,
     {:incorrect,
         %{failures_remaining: 9, guessed: ["x", "e"], id: "MY_ID",
               puzzle: ["_", "_", "_", "_", " ", "_", "_", " ", "_", "_", " ", "_", "e",
                             "_", "_", "e", "_", "!"], status: :in_progress}}}
  ```
  * `connect(id)` - Creates a new game session registered under `id`. Returns the current game session state if `id` is already a registered process (the same result as calling `get(id)`).
  * `guess(id, letter)` - Checks if `letter` is found in the secret word/phrase for the game sesssion associated with `id`. `letter` should be a single character string (e.g. "p"). The result of the guess is returned with the updated game session state. When `:game_over` is returned, the registered game session process is terminated.
  * `get(id)` - Returns the current state of the game session registered with `id`.
  """

  alias Hangman.GameSupervisor

  @doc """
  Spawns a new GameSession and returns `{:ok, state}` where
  `state` is the initial GameSession state.
  If a GameSession is already spawned under the given
  `id`, the current state of that GameSession is returned.
  """
  def connect(id) do
    with {:ok, _pid} <- GameSupervisor.spawn_session(id),
         {:ok, state} <- get(id) do
           {:ok, state}
    else
      {:error, :failed_start} ->
        {:error, "Failed to start GameSession"}
      _ ->
        {:error, "Could not connect GameSession"}
    end
  end

  @doc """
  Returns current state of the GameSession of assoicated
  `id`.
  """
  def get(id),
    do: try_call(id, :get_session)

  @doc """
  Checks if the given `letter` is found anywhere in the
  `secret` GameSession associated with `id`. `letter` is
  expected to be an alpha character.

  Returns `{:error, message}` if an invalid character is
  provided as a guess.
  Returns `{:ok, reply}` if a valid guess is made.

  `reply` will be one of three outcomes:
  * `{:correct, state}` - The guess was correct and
  progress has been made on solving the puzzle.
  * `{:incorrect, state}` - The guess was incorrect and
  the `failures_remaining` count has been decremented.
  * `{:game_over, state}` - The guess result has caused
  either the win or lose condition to be met. The
  GameSession process has terminated and `state` is the
  final game state including the hidden `secret`.
  `state.status` will either be `:won` or `:lost`
  respective to the outcome of the game.
  """
  def guess(id, letter) when is_binary(letter) and byte_size(letter) == 1 do
    guess = String.downcase(letter)
    make_guess(id, guess, guess =~ ~r/[a-z]/)
  end

  defp make_guess(id, letter, true),
    do: try_call(id, {:make_guess, letter})
  defp make_guess(_, _, _),
    do: {:error, :invalid_character}

  defp try_call(id, msg),
    do: call_pid(GenServer.whereis({:global, {:session, id}}), msg)

  defp call_pid(nil, _),
    do: {:error, :not_spawned}
  defp call_pid(pid, msg),
    do: GenServer.call(pid, msg)
end
