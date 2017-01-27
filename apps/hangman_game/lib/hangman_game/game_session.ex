defmodule HangmanGame.GameSession do
  use GenServer
  require Logger

  @private_keys [:secret]
  
# # # # # # # # # # # # # # # # # # # # # #
#               CLIENT API
# # # # # # # # # # # # # # # # # # # # # #
  
  @doc """
  Spawns a new GameSession and returns `{:ok, state}` where
  `state` is the initial GameSession state.
  If a GameSession is already spawned under the given
  `id`, the current state of that GameSession is returned.
  """
  def connect(id) do
    with {:ok, _pid} <- HangmanGame.GameSupervisor.spawn_session(id),
         {:ok, state} <- get(id) do
           {:ok, state}
    else
      _ -> {:error, "Count not connect GameSession"}
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

  @doc """
  Creates new GameSession process and registers under the global
  namespace as `{:session, id}`.

  See `init/1` callback.
  """
  def start_link(id),
    do: GenServer.start_link(__MODULE__, id, name: {:global, {:session, id}})

# # # # # # # # # # # # # # # # # # # # # #
#            SERVER CALLBACKS
# # # # # # # # # # # # # # # # # # # # # #

  def init(id) do
    secret = "this is my secret!"
    state = %{
      id: id,
      status: :new_game,
      secret: secret,
      puzzle: get_puzzle(secret, []),
      guessed: [],
      failures_remaining: 10}
    {:ok, state}  
  end

  def handle_call(:get_session, _, state),
    do: {:reply, {:ok, mask(state)}, state}

  def handle_call({:make_guess, letter}, _, %{guessed: guessed} = state) do
    is_repeat_guess = Enum.member?(guessed, letter)
    handle_guess(is_repeat_guess, letter, state)
  end


  defp handle_guess(true, letter, state),
    do: {:reply, {:error, {:already_guessed, letter}}, state}
  defp handle_guess(_, letter, %{secret: sec, failures_remaining: fails} = state) do
    {guess_result, fails_left} = check_guess(String.contains?(sec, letter), fails)
    state = %{state |
              guessed: [letter | state.guessed],
              failures_remaining: fails_left,
              status: :in_progress}
    handle_result(guess_result, state)
  end

  defp handle_result(:incorrect, %{failures_remaining: 0} = state),
    do: game_over(:lose, state) 
  defp handle_result(:incorrect, state),
    do: {:reply, {:ok, {:incorrect, mask(state)}}, state} 
  defp handle_result(:correct, %{secret: sec, guessed: guessed} = state),
    do: handle_correct(%{state| puzzle: get_puzzle(sec, guessed)})

  defp handle_correct(%{secret: secret, puzzle: puzzle} = state),
    do: send_correct_reply(winner?(secret, puzzle), state)

  defp send_correct_reply(true, state),
    do: game_over(:win, state)
  defp send_correct_reply(_, state),
    do: {:reply, {:ok, {:correct, mask(state)}}, state}  

  defp game_over(:lose, state),
    do: {:stop, :normal, {:ok, {:game_over, %{state | status: :lost}}}, nil}   
  defp game_over(:win, state),
    do: {:stop, :normal, {:ok, {:game_over, %{state | status: :won}}}, nil}

 # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # #

  defp convert_letter(char),
    do: convert_letter(char, [])
  defp convert_letter(char, []),
    do: if char =~ ~r/[a-z]/, do: "_", else: char
  defp convert_letter(char, guessed),
    do: if Enum.member?(guessed, char), do: char, else: convert_letter(char) 

  defp get_puzzle(secret, guessed) do
    secret
    |> String.codepoints
    |> Enum.map(fn x -> convert_letter(x, guessed) end) 
  end

  defp check_guess(true, fails), do: {:correct, fails}
  defp check_guess(_, fails), do: {:incorrect, fails - 1}

  defp winner?(secret, puzzle),
    do: secret == to_string(puzzle)

  defp mask(state),
    do: filter_private(state, @private_keys)
  
  defp filter_private(state, nil),
    do: state
  defp filter_private(state, keys) do
    Enum.reduce(keys, state, fn(key, acc) ->
      Map.delete(acc, key)
    end)
  end

  defp try_call(id, msg),
    do: call_pid(GenServer.whereis({:global, {:session, id}}), msg)

  defp call_pid(nil, _),
    do: {:error, :not_spawned}
  defp call_pid(pid, msg),
    do: GenServer.call(pid, msg)
end
