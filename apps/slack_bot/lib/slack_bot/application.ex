defmodule SlackBot.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    slack_token = Application.get_env(:slack_bot, SlackBot.Slack)[:token]

    IO.puts("STARTING BOT")

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: SlackBot.Worker.start_link(arg1, arg2, arg3)
      # worker(SlackBot.Worker, [arg1, arg2, arg3]),
      worker(SlackBot.Slack, [slack_token])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SlackBot.Supervisor]
   IO.inspect Supervisor.start_link(children, opts)
  end
end
