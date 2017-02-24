defmodule Slack.Plug.ParseAction do
  @moduledoc """
  Fetches the action from the Slack action payload in `conn.params`
  and converts the payload to a `Slack` struct.
  
  The action and converted payload are assigned to `conn`
  as private resources, `:slack_action` and `:slack_params`,
  respectively. Only the first action is assigned if more than
  one action is specified in the request actions list.

  If a "payload" param is not found or is not valid JSON,
  `:slack_action` and `:slack_params` will be `nil`.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts),
    do: parse_payload(conn)

  defp parse_payload(%{params: %{"payload" => json}} = conn) do
    with {:ok, payload} <- Poison.decode(json),
         {:ok, slack}   <- convert_payload(payload) do
         #action         <- get_action(slack.actions) do
         #  conn
         #  |> assign(:slack, slack)
         #  |> assign(:slack_token, slack.token)
         #  |> assign(:current_action, action)
           conn
    end
  end
  defp parse_payload(conn),
    do: nil 

  defp convert_payload(payload) do
    keys = [:actions, :callback_id, :team, :channel,
            :user, :action_ts, :message_ts, :attachment_id,
            :token, :original_message, :response_url]
          #convert_to_atom_keys(payload, keys) 
    keys
  end
end

