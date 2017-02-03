defmodule HangmanWeb.Slack.CommandsControllerTest do
  use HangmanWeb.ConnCase

  describe "POST /hangman/play" do
    test "with invalid slack token, should send 400 error response" do
      res = post(build_conn(), "/hangman/play", %{"token" => "INVALID"})
      assert res.status == 400 
    end

    test "with valid slack token, should send welcome Slack message with Play button" do
      res = post(build_conn(), "/hangman/play", %{"token" => "SLACK_MSG_TOKEN"})
      {:ok, expected_msg} = Poison.encode(HangmanWeb.Slack.ActionButtons.welcome_msg())
      assert res.status == 200
      assert res.resp_body == expected_msg 
    end
  end

  describe "POST /hangman/guess" do
    test "with invalid slack token, should send 400 error response" do
      res = post(build_conn(), "/hangman/guess", %{"token" => "INVALID"})
      assert res.status == 400 
    end

    test "with valid slack token, should send 200 response" do
      res = post(build_conn(), "/hangman/guess", %{"token" => "SLACK_MSG_TOKEN"})
      assert res.status == 200 
    end
  end
end
