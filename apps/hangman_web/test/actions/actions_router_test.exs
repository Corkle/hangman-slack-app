defmodule HangmanWeb.ActionsRouterTest do
  use HangmanWeb.ConnCase
  alias HangmanWeb.ActionsRouter

  defmodule DispatcherMock do
    # Echo args back
    def dispatch(conn, action, slack) do
      {:ok, {conn, action, slack}}
    end
  end

  describe "init/1" do
    test "when :dispatcher option is not passed, should raise exception" do
      assert_raise ArgumentError, fn ->
        ActionsRouter.init([])
      end
    end

    test "when a :dispatcher module is passed, should return the module" do
      dispatcher = DispatcherMock 
      assert ^dispatcher = ActionsRouter.init([{:dispatcher, dispatcher}])
    end
  end
  
  describe "call/2" do
    test "when no action is found in conn.assigns.action, should should raise exception" do
      conn = build_conn()
      assert_raise ArgumentError, fn ->
        ActionsRouter.call(conn, DispatcherMock)   
      end
    end

    test "with empty :actions list in assigns.action, should call dispatcher.dispatch/3 with nil action" do
      conn = build_conn() |> assign(:action, %{actions: []})
      assert {:ok, {^conn, nil, _slack}} = ActionsRouter.call(conn, DispatcherMock)
    end

    test "with nil value for :actions, should call dispatcher.dispatch/3 with nil action" do
      conn = build_conn() |> assign(:action, %{actions: nil})
      assert {:ok, {^conn, nil, _slack}} = ActionsRouter.call(conn, DispatcherMock)
    end

    test "with one action in :actions list, should call dispatcher.dispatch/3 with that action" do
      action = %{"name" => "action_1", "value" => 1} 
      slack = %{actions: [action]}
      conn = build_conn() |> assign(:action, slack)
      assert {:ok, {^conn, ^action, ^slack}} = ActionsRouter.call(conn, DispatcherMock) 
    end

    test "with more than one action in :actions list, should call dispatch/3 with first action" do
      action_1 = %{"name" => "action_1", "value" => 1} 
      action_2 = %{"name" => "action_2", "value" => 2} 
      action_3 = %{"name" => "action_3"}
      slack = %{actions: [action_1, action_2, action_3]}
      conn = build_conn() |> assign(:action, slack)
      assert {:ok, {^conn, ^action_1, ^slack}} = ActionsRouter.call(conn, DispatcherMock)
    end
  end
end
