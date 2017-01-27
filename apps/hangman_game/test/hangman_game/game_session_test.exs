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
    test "with a new session id, should return new session with intial state" do
      assert {:ok, state} = GameSession.connect("NEW_ID")
      assert state.id == "NEW_ID"
      assert state.status == :new_game
      assert state.guessed == []
      assert state.puzzle != nil 
      assert state.failures_remaining == 10
      assert !Map.has_key?(state, :secret) 
    end

    test "with a session id with already spawned server, should return current state of that server" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      GameSession.guess("SESSION_ID", "p")
      {:ok, {_, state}} = GameSession.guess("SESSION_ID", "x")
      assert state.guessed == ["x", "p"]
      assert state.status == :in_progress
      assert {:ok, ^state} = GameSession.connect("SESSION_ID")
    end
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
      assert state.status == :new_game
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

    test "when letter has a length != 1, should raise exception" do
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "aa")
      end
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "ABC")
      end
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "a1")
      end
      assert_raise FunctionClauseError, fn ->
        GameSession.guess("ID", "")
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
  
    test "with a valid guess, should return :ok with either :correct or :incorrect with updated state. Status should update to :in_progress" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, %{status: :new_game}} = GameSession.get("SESSION_ID")
      assert {:ok, {guess_result, state}} = GameSession.guess("SESSION_ID", "e") 
      assert Enum.member?([:correct, :incorrect], guess_result)
      assert %{status: :in_progress, puzzle: _, guessed: ["e"], failures_remaining: _, id: "SESSION_ID"} = state
    end

    test "with a letter that has already been guessed, should return :already_guessed error" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, _} = GameSession.guess("SESSION_ID", "e")
      assert {:error, {:already_guessed, "e"}} = GameSession.guess("SESSION_ID", "e")
    end

    test "with an uppercase letter guess, should make guess as lowercase and return status and state" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, {status, state}} = GameSession.guess("SESSION_ID", "A") 
      assert Enum.member?([:correct, :incorrect], status)
      assert %{status: status, puzzle: _, guessed: guessed, failures_remaining: _, id: "SESSION_ID"} = state
      assert guessed == ["a"] 
      assert status == :in_progress
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
