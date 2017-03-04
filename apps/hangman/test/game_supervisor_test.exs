defmodule Hangman.GameSupervisorTest do
  use ExUnit.Case
  alias Hangman.GameSupervisor

  describe "spawn_session/1" do
    test "with new id, should start process and return pid" do
      assert {:ok, _pid} = GameSupervisor.spawn_session("ID")
    end

    test "with id for session that is already spawned, should return pid for existing process" do
      assert {:ok, pid} = GameSupervisor.spawn_session("MY_ID")
      assert {:ok, ^pid} = GameSupervisor.spawn_session("MY_ID")
    end
  end
end
