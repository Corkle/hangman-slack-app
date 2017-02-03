defmodule HangmanWeb.SlackWorkerTest do
  use ExUnit.Case
  alias HangmanWeb.SlackWorker

  describe "dispatch(:play, slack)" do
    test "when a user has not started a game,
      should start new game session and respond with game details." do
      assert false
    end
  end
end
