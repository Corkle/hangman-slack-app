defmodule HangmanWeb.Slack.Messages do
  @moduledoc """
  Templates for commonly used Slack message responses.
  """

  def button(text, name, opts \\ []) do
    style = Keyword.get(opts, :style, "default")
    %{text: text, name: name, style: style, type: "button"}
    |> add_opt(opts, :value)
    |> add_opt(opts, :confirm)
  end

  defp add_opt(map, opts, key) do
    case Keyword.get(opts, key) do
      nil -> map
      val -> Map.put(map, key, val)
    end
  end

  def welcome_msg do
    %{text: "Hey pal, you looking to kill some time with a game?",
      attachments: [%{
        text: "What would you like to do?",
        callback_id: "play",
        color: "#3AA344",
        actions: [
          button("Play", "play_game", [style: "primary"])
        ]}
      ]}
  end

  def guess_param_error do
    %{attachments: [
      %{color: "danger",
        text: "Oops! You must make a guess with a single letter (e.g. \"/guess b\")"}]}
  end

  def game_not_started_error do
    %{attachments: [
      %{color: "warning",
        text: "Oops! You aren't playing a game yet. Type \"/playhangman\" to start one!"}]}
  end

  def already_guessed_error(char) do
    %{attachments: [
      %{color: "warning",
        text: "Oops! You already guessed the letter \"#{char}\""}]}
  end
end
