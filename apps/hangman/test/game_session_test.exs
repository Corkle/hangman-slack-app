defmodule Hangman.GameSessionTest do
  use ExUnit.Case
  alias Hangman.GameSession

  defp convert_letter(char),
    do: if char =~ ~r/[a-z]/, do: "_", else: char

  defp puzzle_from_secret(secret) do
    secret
    |> String.downcase
    |> String.codepoints
    |> Enum.map(fn x -> convert_letter(x) end) 
  end
  
# # # # # # # # # # # # # # # # # # # # # #
#            SERVER CALLBACKS
# ----------------------------------------
# Callback tests do not spin up a process,
# but use mock state. Internal state change
# can be tested here.
# # # # # # # # # # # # # # # # # # # # # #

  describe "init/1" do
    test "with a new session id, should return initial state" do
      assert {:ok, state} = GameSession.init("ID")
      assert state.id == "ID"
      assert state.status == :new_game
      assert is_bitstring(state.secret) 
      assert state.puzzle == puzzle_from_secret(state.secret) 
      assert state.guessed == [] 
      assert state.failures_remaining == 10
    end
  end

  describe "handle_call :get_session" do
    test "should return current state" do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: puzzle_from_secret("my secret!"),
        guessed: ["p", "f", "o"],
        failures_remaining: 7}
      expected_reply = {:ok, Map.delete(state, :secret)}

      assert {:reply, ^expected_reply, ^state} = GameSession.handle_call(:get_session, nil, state)
    end
  end

  describe "handle_call {:make_guess, letter}" do
    test "with a letter that is found in the secret, should update puzzle, guessed and return :correct status with updated state" do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["m", "_", " ", "s", "_", "_", "_", "_", "_", "!"],
        guessed: ["m", "s"],
        failures_remaining: 10}
      expected_state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["m", "_", " ", "s", "e", "_", "_", "e", "_", "!"],
        guessed: ["e", "m", "s"],
        failures_remaining: 10}
      expected_reply = {:ok, {:correct, Map.delete(expected_state, :secret)}} 
      assert {:reply, ^expected_reply, ^expected_state} = GameSession.handle_call({:make_guess, "e"}, nil, state) 
    end

    test "with a letter that is not found in secret, should decrement failures_remaining, update guessed and return :incorrect with updated state" do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["s", "t"],
        failures_remaining: 10}
      expected_state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["g", "s", "t"],
        failures_remaining: 9}
      expected_reply = {:ok, {:incorrect, Map.delete(expected_state, :secret)}}
      assert {:reply, ^expected_reply, ^expected_state} = GameSession.handle_call({:make_guess, "g"}, nil, state)
    end

    test "with a letter that has already been guessed, should reply with :already_guessed error" do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["s", "t"],
        failures_remaining: 10}
      expected_reply = {:error, {:already_guessed, "t"}} 
      assert {:reply, ^expected_reply, ^state} = GameSession.handle_call({:make_guess, "t"}, nil, state)
    end
    
    test "with an incorrect guess and failures_remaining == 1, should return status :game_over with final state and revealed secret." do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["a", "b", "d", "f", "g", "h", "i", "j", "k", "s", "t"],
        failures_remaining: 1}
      expected_state = %{
        id: "ID",
        status: :lost,
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["l", "a", "b", "d", "f", "g", "h", "i", "j", "k", "s", "t"],
        failures_remaining: 0}
      expected_reply = {:ok, {:game_over, expected_state}} 
      assert {:stop, :normal, ^expected_reply, nil} =
        GameSession.handle_call({:make_guess, "l"}, nil, state)
    end

    test "with a correct guess that completes the puzzle, should return status :game_over with final state and revealed secret." do
      state = %{
        id: "ID",
        status: :in_progress,
        secret: "my secret!",
        puzzle: ["_", "y", " ", "s", "e", "c", "r", "e", "t", "!"],
        guessed: ["y", "s", "c", "r", "e", "t", "x"],
        failures_remaining: 9}
      expected_state = %{
        id: "ID",
        status: :won,
        secret: "my secret!",
        puzzle: ["m", "y", " ", "s", "e", "c", "r", "e", "t", "!"],
        guessed: ["m", "y", "s", "c", "r", "e", "t", "x"],
        failures_remaining: 9}
      expected_reply = {:ok, {:game_over, expected_state}}
      assert {:stop, :normal, ^expected_reply, nil} =
        GameSession.handle_call({:make_guess, "m"}, nil, state)
    end
  end
end

