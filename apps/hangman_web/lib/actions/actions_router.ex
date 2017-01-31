defmodule HangmanWeb.ActionsRouter do
  import Plug.Conn

  @doc """
  Initializes the plug with the action dispatcher module
  which defines the `dispatch/3` function.
  An error is raised if no option is specified for :dispatcher.
  """
  def init(dispatcher: dispatcher), do: dispatcher 
  def init(_), do: raise(ArgumentError, message: ":dispatcher not found.")

  @doc """
  Expects Slack data in `conn.assigns.action` to
  contain a button action in the `actions` list.
  If one or more action is found, ActionsRouter calls
  HangmanWeb.ActionsController.dispatch/3 with the
  first action as the second argument.
  If `actions` is `nil` or an empty list, dispatch/3
  is called with `nil` for the second argument.
  """
  def call(%{assigns: %{action: action}} = conn, dispatcher),
    do: dispatch_action(conn, dispatcher, action)

  def call(_, _) do
    msg = "Action not found. Make sure to use HangmanWeb.SlackPlugs.parse_action_payload plug before this plug is called."
    raise(ArgumentError, message: msg)
  end
  
  defp dispatch_action(conn, dispatcher, %{actions: actions} = slack),
    do: dispatcher.dispatch(conn, get_action(actions), slack)
  defp dispatch_action(conn, dispatcher, slack),
    do: dispatcher.dispatch(conn, nil, slack) 

  defp get_action([action]), do: action
  defp get_action([action | _]), do: action
  defp get_action([]), do: nil
  defp get_action(nil), do: nil
end
