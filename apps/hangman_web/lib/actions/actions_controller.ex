defmodule HangmanWeb.ActionsController do
  use HangmanWeb.Web, :controller

  def start(conn, params) do
    IO.inspect(params)
    send_response(conn, start_msg())
  end

  def dispatch(conn, %{"payload" => json_msg}) do
    payload =
      with {:ok, msg} <- Poison.decode(json_msg) do
          msg["actions"]      
      else
        _ -> %{error: "ERROR"}
      end

    send_response(conn, payload)
  end

  defp send_response(conn, payload \\ %{}),
    do: conn |> put_status(200) |> json(payload)

  defp start_msg do
    %{
      text: "Hey pal, you looking to kill some time with a game?",
      attachments: [%{
        text: "What would you like to do?",
        callback_id: "play_123", 
        color: "#3AA344",
        actions: [
          %{name: "play_game",
            text: "Play",
            type: "button",
            style: "primary",
            value: "play_game"},
          %{name: "help",
            text: "Help",
            type: "button",
            value: "help"},
          %{name: "cancel",
            text: "End Current Game",
            style: "danger",
            type: "button",
            value: "cancel",
            confirm: %{
              title: "Are you sure?",
              text: "This will delete your current progress?",
              ok_text: "Yes",
              dismiss_text: "No"}}
        ]}
      ]}
  end

end
