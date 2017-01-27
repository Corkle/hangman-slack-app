defmodule HangmanWeb.SlackPlugs do
  import Plug.Conn

  @doc """
  If request is a valid Slack Command request, `conn.params`
  should contain the string keys for the command.
  `parse_command_data` converts only these expected params
  into an atom-keyed map which is assigned to `conn` under
  `:command` and the "token" param under `:slack_token`.
  If any expected keys are missing from `conn.params`, they will
  be set to `nil` under the respective key in `:command`.
  """
  def parse_command_data(conn, _) do
    keys = [:channel_id, :channel_name, :command,
            :response_url, :team_domain, :team_id,
            :text, :token, :user_id, :user_name]
    data = convert_to_atom_keys(conn.params, keys)
    conn
    |> assign(:command, data)
    |> assign(:slack_token, data.token)
  end

  @doc """
  If request is a valid Slack Interactive Message request,
  `conn.params` should contain a `"payload"` key with a
  JSON value representing the Slack message data.
  `parse_action_payload` decodes the JSON object and
  converts the expected Slack fields into an atom-keyed map
  which is assigned to `conn` under `:action`. The "token"
  field is also assigned under `:slack_token`.

  If the `"payload"` param is not found or does not resolve
  to valid JSON format, the Plug pipeline is halted and
  the request is sent a 400 status response.
  """
  def parse_action_payload(%{params: %{"payload" => json}} = conn, _),
    do: decode_payload(conn, Poison.decode(json))
  def parse_action_payload(conn, _),
    do: bad_request(conn)
  
  defp decode_payload(conn, {:ok, payload}),
    do: convert_payload(conn, payload)
  defp decode_payload(conn, _),
    do: bad_request(conn)

  defp convert_payload(conn, payload) do
    keys = [:actions, :callback_id, :team, :channel,
            :user, :action_ts, :message_ts, :attachment_id,
            :token, :original_message, :response_url]
    data = convert_to_atom_keys(payload, keys) 
    conn
    |> assign(:action, data)
    |> assign(:slack_token, data.token)
  end

  @doc """
  Checks `conn.assigns.slack_token` and compares it to the
  token passed as the second function argument. `conn` is
  returned, unchanged, if the tokens are a match.
  If the tokens do not match or if `nil` is passes for the
  argument token, the Plug pipeline is halted and the
  request is sent a 400 status response.
  """
  def verify_slack_token(conn, nil),
    do: bad_request(conn)
  def verify_slack_token(%{assigns: %{slack_token: from_token}} = conn, token)
    when from_token == token,
    do: conn
  def verify_slack_token(conn, _),
    do: bad_request(conn) 

  defp bad_request(conn),
    do: conn |> put_status(400) |> halt

  defp convert_to_atom_keys(params, keys) do
    Enum.reduce(keys, %{}, fn key, acc ->
      val = Map.get(params, Atom.to_string(key))
      Map.put(acc, key, val) 
    end)
  end
end
