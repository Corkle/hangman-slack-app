defmodule HangmanTest do
  use ExUnit.Case
  alias Hangman.GameSession

  describe "connect/1" do
    test "with a new session id, should return new session with intial state" do
      assert {:ok, state} = Hangman.connect("NEW_ID")
      assert state.id == "NEW_ID"
      assert state.status == :new_game
      assert state.guessed == []
      assert state.puzzle != nil 
      assert state.failures_remaining == 10
      assert !Map.has_key?(state, :secret) 
    end

    test "with a session id with already spawned server, should return current state of that server" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      Hangman.guess("SESSION_ID", "p")
      {:ok, {_, state}} = Hangman.guess("SESSION_ID", "x")
      assert state.guessed == ["x", "p"]
      assert state.status == :in_progress
      assert {:ok, ^state} = Hangman.connect("SESSION_ID")
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
      assert {:error, :not_spawned} = Hangman.get("NOT_SPAWNED")
    end

    test "with an id that has a spawned server, should return state without secret" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, state} = Hangman.get("SESSION_ID")
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
      assert {:error, :not_spawned} = Hangman.guess("NOT_SPAWNED", "h")
    end

    test "with a non-binary value for letter, should raise exception" do
      assert_raise FunctionClauseError, fn ->
        Hangman.guess("ID", 4)
      end
    end

    test "when letter has a length != 1, should raise exception" do
      assert_raise FunctionClauseError, fn ->
        Hangman.guess("ID", "aa")
      end
      assert_raise FunctionClauseError, fn ->
        Hangman.guess("ID", "ABC")
      end
      assert_raise FunctionClauseError, fn ->
        Hangman.guess("ID", "a1")
      end
      assert_raise FunctionClauseError, fn ->
        Hangman.guess("ID", "")
      end
    end

    test "with a non-alpha character, should return :invalid_character error" do
      assert {:error, :invalid_character} == Hangman.guess("ID", "4")
      assert {:error, :invalid_character} == Hangman.guess("ID", ".")
      assert {:error, :invalid_character} == Hangman.guess("ID", " ")
      assert {:error, :invalid_character} == Hangman.guess("ID", "\\")
      assert {:error, :invalid_character} == Hangman.guess("ID", "<")
      assert {:error, :invalid_character} == Hangman.guess("ID", "_")
      assert {:error, :invalid_character} == Hangman.guess("ID", "&")
    end
  
    test "with a valid guess, should return :ok with either :correct or :incorrect with updated state. Status should update to :in_progress" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, %{status: :new_game}} = Hangman.get("SESSION_ID")
      assert {:ok, {guess_result, state}} = Hangman.guess("SESSION_ID", "e") 
      assert Enum.member?([:correct, :incorrect], guess_result)
      assert %{status: :in_progress, puzzle: _, guessed: ["e"], failures_remaining: _, id: "SESSION_ID"} = state
    end

    test "with a letter that has already been guessed, should return :already_guessed error" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, _} = Hangman.guess("SESSION_ID", "e")
      assert {:error, {:already_guessed, "e"}} = Hangman.guess("SESSION_ID", "e")
    end

    test "with an uppercase letter guess, should make guess as lowercase and return status and state" do
      {:ok, _pid} = GameSession.start_link("SESSION_ID")
      assert {:ok, {status, state}} = Hangman.guess("SESSION_ID", "A") 
      assert Enum.member?([:correct, :incorrect], status)
      assert %{status: status, puzzle: _, guessed: guessed, failures_remaining: _, id: "SESSION_ID"} = state
      assert guessed == ["a"] 
      assert status == :in_progress
    end
  end
end
