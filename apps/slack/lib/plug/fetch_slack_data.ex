defmodule Slack.Plug.FetchSlackData do
  @moduledoc """
  Fetches the Slack data from `conn.params` and converts
  it to a `Slack` struct stored as `private` in `conn` as
  `slack_data`.
  
  Missing fields will default to `nil`. If no Slack data is
  found in `conn.params`, `:slack_data` will be `nil`.

  Interactive Messages and Slash Commands are currently supported
  Slack request types.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts),
    do: fetch_slack_data(conn)

  defp fetch_slack_data(%{params: %{"payload" => json}} = conn) do
    with {:ok, payload} <- get_payload(json),
         {:ok, slack}   <- Slack.create(payload) do
           put_slack_data(conn, slack) 
    else
      _ -> put_slack_data(conn, nil)
    end
  end
  defp fetch_slack_data(conn),
    do: put_slack_data(conn, nil) 

  defp get_payload(json),
    do: Poison.decode(json)

  defp put_slack_data(conn, value),
    do: put_private(conn, :slack_data, value)
end
