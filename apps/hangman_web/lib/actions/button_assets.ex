defmodule HangmanWeb.Actions.ButtonAssets do
  def button(text, id),
    do: button(text, id, id, "default")
  def button(text, id, style),
    do: button(text, id, id, style)
  def button(text, id, val, style),
    do: %{text: text, name: id, value: val, style: style, type: "button"} 

  def conf_button(text, id, val, style, conf),
    do: %{text: text, name: id, value: val, style: style, conf: conf, type: "button"}

  def welcome_msg do
    %{text: "Hey pal, you looking to kill some time with a game?",
      attachments: [%{
        text: "What would you like to do?",
        callback_id: "play_123", 
        color: "#3AA344",
        actions: [
          button("Play", "play_game", "primary"),
        ]}
      ]}
  end
end

