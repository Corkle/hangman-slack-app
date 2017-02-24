defmodule HangmanWeb.Slack.ActionsController do
  #use HangmanWeb.Web, :controller
   use Phoenix.Controller 

  def action(%{assigns: %{slack: slack, current_action: action}} = conn, _),
    do: apply(__MODULE__, action_name(conn), [conn, action, slack])

  def dispatch(conn, "play_game", slack) do
    slack_worker(conn).dispatch(:play, slack)
    msg = %{text: "Please wait..."}
    send_response(conn, {:ok, msg})
  end

  def dispatch(conn, _, _),
    do: conn |> put_status(200)

  defp send_response(conn, {:error, error}),
    do: conn |> put_status(500) |> json(error)
  defp send_response(conn, {:ok, payload}),
    do: conn |> put_status(200) |> json(payload)

  defp slack_worker(conn),
    do: conn.private[:slack_action_worker] || HangmanWeb.SlackWorker
end



