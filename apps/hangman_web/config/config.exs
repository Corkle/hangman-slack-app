# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :hangman_web, HangmanWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OM7XXuGEYZDH2KsLbvU9EBVPYlevVUj8Lixpq7f+xKXg4vDUTxdWQQlRNEVi++xP",
  render_errors: [view: HangmanWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: HangmanWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Public Slack App Id
config :hangman_web, :slack_app_client_id, "19427839078.126988800178"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
