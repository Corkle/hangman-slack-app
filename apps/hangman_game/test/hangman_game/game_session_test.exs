defmodule HangmanGame.GameSessionTest do
  use ExUnit.Case
  alias HangmanGame.GameSession

  defp convert_letter(char),
    do: if char =~ ~r/[a-z]/, do: "_", else: char

  defp puzzle_from_secret(secret) do
    secret
    |> String.downcase
    |> String.codepoints
    |> Enum.map(fn x -> convert_letter(x) end) 
  end

  describe "connect/1" do
    @tag :todo
    test "with a new session id, should return new session with intial state"
    @tag :todo
    test "with a sessoin id with already spawned server, should return current state of that server"
  end

# # # # # # # # # # # # # # # # # # # # # #
#               CLIENT API
# ----------------------------------------
# Client API tests will spin up a process
# before each test. Only return output is
# tested here.
# # # # # # # # # # # # # # # # # # # # # #

  describe "get/1" do
    test "with an id that does not have a spawned server, should return :not_spanwed error" do
      assert {:error, :not_spawned} = GameSession.get("NOT_SPAWNED")
    end

    test "with an id that has a spawned server, should return state without secret" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, state} = GameSession.get("SESSION_ID")
      assert state.id == "SESSION_ID"
      assert state.guessed == []
      assert state.puzzle != nil 
      assert state.failures_remaining == 10
      assert !Map.has_key?(state, :secret) 
    end
  end

  describe "guess/2" do
    test "with a session id that has not been spawned, should return :not_spawned error" do
      assert {:error, :not_spawned} = GameSession.guess("NOT_SPAWNED", "h")
    end

    test "with a non-binary value for letter, should raise exception" do
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", 4)
      end
    end

    test "when letter has a length greater than 1, should raise exception" do
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "aa")
      end
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "ABC")
      end
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "a1")
      end
    end

    test "with a non-alpha character, should return :invalid_character error" do
      assert {:error, :invalid_character} == GameSession.guess("ID", "4")
      assert {:error, :invalid_character} == GameSession.guess("ID", ".")
      assert {:error, :invalid_character} == GameSession.guess("ID", " ")
      assert {:error, :invalid_character} == GameSession.guess("ID", "\\")
      assert {:error, :invalid_character} == GameSession.guess("ID", "<")
      assert {:error, :invalid_character} == GameSession.guess("ID", "_")
      assert {:error, :invalid_character} == GameSession.guess("ID", "&")
    end
  
    test "with a valid guess, should return :ok with either :correct or :incorrect status with updated state" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, {status, state}} = GameSession.guess("SESSION_ID", "e") 
      assert Enum.member?([:correct, :incorrect], status)
      assert %{puzzle: _, guessed: guessed, failures_remaining: _, id: "SESSION_ID"} = state
      assert length(guessed) == 1
    end

    test "with a letter that has already been guessed, should return :already_guessed error" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, _} = GameSession.guess("SESSION_ID", "e")
      assert {:error, {:already_guessed, "e"}} = GameSession.guess("SESSION_ID", "e")
    end
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
        secret: "my secret!",
        puzzle: ["_", "_", " ", "_", "_", "_", "_", "_", "_", "!"],
        guessed: [],
        failures_remaining: 10}
      expected_state = %{
        id: "ID",
        secret: "my secret!",
        puzzle: ["_", "_", " ", "_", "e", "_", "_", "e", "_", "!"],
        guessed: ["e"],
        failures_remaining: 10}
      expected_reply = {:ok, {:correct, Map.delete(expected_state, :secret)}} 
      assert {:reply, ^expected_reply, ^expected_state} = GameSession.handle_call({:make_guess, "e"}, nil, state) 
    end

    test "with a letter that is not found in secret, should decrement failures_remaining, update guessed and return :incorrect with updated state" do
      state = %{
        id: "ID",
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["s", "t"],
        failures_remaining: 10}
      expected_state = %{
        id: "ID",
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
        secret: "my secret!",
        puzzle: ["_", "_", " ", "s", "_", "_", "_", "_", "t", "!"],
        guessed: ["s", "t"],
        failures_remaining: 10}
      expected_reply = {:error, {:already_guessed, "t"}} 
      assert {:reply, ^expected_reply, ^state} = GameSession.handle_call({:make_guess, "t"}, nil, state)
    end
  end
end
