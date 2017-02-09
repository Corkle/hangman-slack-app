defmodule HangmanWeb.Slack.CommandsController do
  use HangmanWeb.Web, :controller
  import HangmanWeb.Slack.ActionButtons,
    only: [welcome_msg: 0]
    
  def action(%{assigns: %{slack: slack}} = conn, _),
    do: apply(__MODULE__, action_name(conn), [conn, slack.text, slack])

  def start(conn, _, _) do
    conn
    |> put_status(200)
    |> json(welcome_msg())
  end

  def guess(conn, value, slack) do
    IO.inspect({value, slack})
    conn
    |> put_status(200)
    |> json("hi") 
  end

  defp slack_worker(conn),
    do: conn.private[:slack_action_worker] || HangmanWeb.SlackWorker
end
