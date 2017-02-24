defmodule Slack.Phoenix.ActionController do
  defmacro __using__(_) do
    quote do
      use Phoenix.Controller
    
      #plug Slack.Plug.ParseParams

      def action(%{private: %{slack_params: slack}} = conn, _),
        do: apply(__MODULE__, action_name(conn), [conn, slack.action, slack])

      def action(conn, _),
        do: apply(__MODULE__, action_name(conn), [conn, conn.params])
    end
  end
end

