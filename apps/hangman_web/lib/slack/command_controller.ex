defmodule HangmanWeb.Slack.CommandController do
  use Slack.Phoenix.ActionController,
    token: Application.get_env(:hangman_web, :slack_message_token)

  import HangmanWeb.Slack.ActionButtons,
    only: [welcome_msg: 0]

  def handle_command("/playhangman", conn, _slack),
    do: send_response(conn, welcome_msg())

  def handle_command("/guess", _conn, _slack),
    do: :todo 

  defp send_response(conn, {:error, error}) do
    conn
    |> put_status(500)
    |> json(error)
  end

  defp send_response(conn, payload) do
    conn
    |> put_status(200)
    |> json(payload)
  end
end
