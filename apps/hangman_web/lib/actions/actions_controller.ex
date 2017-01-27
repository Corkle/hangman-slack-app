defmodule HangmanWeb.ActionsController do
  use HangmanWeb.Web, :controller
  alias HangmanWeb.ActionWorker
  import HangmanWeb.Actions.ButtonAssets,
    only: [welcome_msg: 0]

  def start(conn, _) do
    conn
    |> put_status(200)
    |> json(welcome_msg())
  end

  def guess(conn, params) do
    IO.inspect(params)
    |> put_status(200)
    |> json(welcome_msg()) 
  end

  def dispatch(conn, action, params) do
    IO.inspect(params)
    send_response(conn, {:ok, action["name"]})
  end

  defp send_response(conn, {:error, error}),
    do: conn |> put_status(500) |> json(error)
  defp send_response(conn, {:ok, payload}),
    do: conn |> put_status(200) |> json(payload)
end
