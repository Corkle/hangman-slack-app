defmodule HangmanWeb.Slack.ActionController do
  use Slack.Phoenix.ActionController,
    token: Application.get_env(:hangman_web, :slack_message_token)

  def handle_action(%{name: "play_game"}, conn, slack) do
    slack_worker(conn).play(slack)
    msg = %{text: "Please wait..."}
    send_response(conn, msg)
  end

  def handle_action(_, conn, _),
    do: put_status(conn, 200)

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
