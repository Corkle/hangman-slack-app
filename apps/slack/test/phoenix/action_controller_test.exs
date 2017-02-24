defmodule Slack.Phoenix.ActionControllerTest do
  use ExUnit.Case
  use Plug.Test

  defmodule ActionController do
    use Slack.Phoenix.ActionController

    def dispatch(conn, params) do
      send self(), {:dispatch2, conn} 
      conn
    end

    def dispatch(conn, action, slack) do
      send self(), {:dispatch3, action, slack}
      conn
    end
  end

  defmodule ActionRouter do
    use Phoenix.Router

    post "/", ActionController, :dispatch    
  end

  def post(params) do
    conn(:post, "/", params)
    |> put_private(:slack_params, %{action: "ACTION"})
    |> ActionRouter.call(ActionRouter.init([]))
  end

  test "" do
    post(nil)
    assert_receive nil 
  end
end

