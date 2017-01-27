defmodule HangmanWeb.Plugs.ActionRouter do
  import Plug.Conn

  @slack_keys [:actions, :callback_id, :team, :channel, :user, :action_ts, :message_ts, :attachment_id, :token, :original_message, :response_url]

  def init(options),
    do: options 

  def call(%{body_params: %{"payload" => json}} = conn, _opts) do
    {:ok, payload} = Poison.decode(json)
    IO.inspect @slack_keys
    params = convert_to_atom_keys(payload)
    dispatch_on_action(conn, params)
  end

  defp dispatch_on_action(conn, %{actions: [action]} = params),
    do: HangmanWeb.ActionsController.dispatch(conn, action, params) 


  defp convert_to_atom_keys(params) do
    Enum.reduce(@slack_keys, %{}, fn key, acc ->
      val = Map.get(params, Atom.to_string(key))
      Map.put(acc, key, val) 
    end)
  end
end
