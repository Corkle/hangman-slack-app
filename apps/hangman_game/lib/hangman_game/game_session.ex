defmodule HangmanGame.GameSession do
  use GenServer
  require Logger

  @private_keys [:secret]
  
# # # # # # # # # # # # # # # # # # # # # #
#               CLIENT API
# # # # # # # # # # # # # # # # # # # # # #

  def start_link(id),
    do: GenServer.start_link(__MODULE__, id, name: {:global, {:session, id}})

  @doc """
  Returns current state of the GameSession of assoicated
  `id`.
  """
  def get(id),
    do: try_call(id, :get_session)

  @doc """
  Checks if the given `letter` is found in anywhere in
  the `secret` of the `id` associated GameSession.
  `letter` is expected to be an alpha character.
  """
  def guess(id, letter) when is_binary(letter) and byte_size(letter) == 1 do
    guess = String.downcase(letter)
    make_guess(id, guess, guess =~ ~r/[a-z]/)
  end

  defp make_guess(id, letter, true),
    do: try_call(id, {:make_guess, letter})
  defp make_guess(_, _, _),
    do: {:error, :invalid_character}

  
# # # # # # # # # # # # # # # # # # # # # #
#            SERVER CALLBACKS
# # # # # # # # # # # # # # # # # # # # # #

  def init(id) do
    secret = "this is my secret!"
    state = %{
      id: id,
      secret: secret,
      puzzle: get_puzzle(secret, []),
      guessed: [],
      failures_remaining: 10}
    {:ok, state}  
  end

  def handle_call(:get_session, _, state),
    do: {:reply, {:ok, mask(state)}, state}

  def handle_call({:make_guess, letter}, _, %{guessed: guessed} = state),
    do: handle_guess(Enum.member?(guessed, letter), letter, state)


  defp handle_guess(true, letter, state),
    do: {:reply, {:error, {:already_guessed, letter}}, state}
  defp handle_guess(_, letter, state) do
    %{secret: sec, failures_remaining: fails, guessed: guessed} = state
    {status, fails} = check_guess(String.contains?(sec, letter), fails)
    guessed = [letter | guessed] 
    puzzle = get_puzzle(sec, guessed)
    state =
      %{state | guessed: guessed, puzzle: puzzle, failures_remaining: fails}

    {:reply, {:ok, {status, mask(state)}}, state}  
  end

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
