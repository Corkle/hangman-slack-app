defmodule HangmanWeb.Slack.CommandController do
  use Slack.Phoenix.ActionController,
    token: Application.get_env(:hangman_web, :slack_message_token)

  import HangmanWeb.Slack.Messages,
    only: [welcome_msg: 0, guess_param_error: 0]
  import Plug.Conn

  def handle_command("/playhangman", conn, _slack),
    do: send_response(conn, welcome_msg())

  def handle_command("/guess", conn, %{text: guess} = slack),
    do: handle_guess(conn, slack, guess =~ ~r/^[a-zA-Z]$/)

  defp handle_guess(conn, slack, true) do
    slack_worker(conn).guess(slack.text, slack)
    conn
    |> send_resp(200, "")
  end

  defp handle_guess(conn, slack, _) do
    send_response(conn, guess_param_error())
  end

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

  defp slack_worker(conn),
    do: conn.private[:slack_action_worker] || HangmanWeb.SlackWorker
end
