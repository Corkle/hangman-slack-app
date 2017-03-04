defmodule Hangman.GameSession do
  @moduledoc """
  GenServer module for handling all game logic for unique sessions.
  """
  use GenServer

  alias Hangman.SecretWords

  @private_keys [:secret]

  @doc """
  Creates new GameSession process and registers under the global
  namespace as `{:session, id}`.

  See `init/1` callback.
  """
  def start_link(id),
    do: GenServer.start_link(__MODULE__, id, name: {:global, {:session, id}})

  def init(id) do
    secret = generate_secret()
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

  defp handle_guess(true, letter, state) do
    {:reply, {:error, {:already_guessed, letter}}, state}
  end

  defp handle_guess(_, letter, %{secret: sec, failures_remaining: fails} = state) do
    {guess_result, fails_left} =
      check_guess(String.contains?(sec, letter), fails)
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

  defp generate_secret,
    do: SecretWords.get_random()

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
end
