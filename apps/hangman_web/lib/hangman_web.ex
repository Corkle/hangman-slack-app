defmodule HangmanWeb do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args),
    do: start_if_ready()

  defp start_if_ready do
    env_vars = [:slack_app_secret, :slack_message_token]
    is_vars_loaded = Enum.all?(env_vars, fn var ->
      nil != Application.get_env(:hangman_web, var)
    end)
    do_start(is_vars_loaded)
  end

  defp do_start(true) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(HangmanWeb.Endpoint, []),
      worker(HangmanWeb.SlackWorker, [HangmanWeb.SlackWorker])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HangmanWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp do_start(_) do
    Logger.error("missing one or more required environment variables")
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HangmanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
