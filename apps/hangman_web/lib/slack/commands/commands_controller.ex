defmodule HangmanWeb.Slack.CommandsController do
  use HangmanWeb.Web, :controller
  import HangmanWeb.Slack.ActionButtons,
    only: [welcome_msg: 0]

  def start(conn, _) do
    conn
    |> put_status(200)
    |> json(welcome_msg())
  end

  def guess(conn, _) do
    conn
    |> put_status(200)
  end

  defp send_response(conn, {:error, error}),
    do: conn |> put_status(500) |> json(error)
  defp send_response(conn, {:ok, payload}),
    do: conn |> put_status(200) |> json(payload)
end
