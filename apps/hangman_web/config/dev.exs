use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :hangman_web, HangmanWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :hangman_web,
  hostname: "slashbot.corkbits.com"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :hangman_web, :slack_oauth_api, HangmanWeb.Oauth.Slack.HTTPoison

config :hangman_web, :slack_app_secret, System.get_env("SLACK_APP_SECRET")

config :hangman_web, :slack_message_token, System.get_env("SLACK_MSG_TOKEN")
