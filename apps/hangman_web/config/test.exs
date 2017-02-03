use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hangman_web, HangmanWeb.Endpoint,
  http: [port: 4001],
  server: false

config :hangman_web,
  hostname: "localhost"

# Print only warnings and errors during test
config :logger, level: :warn

config :hangman_web, :slack_oauth_api, HangmanWeb.Oauth.Slack.TestMock

config :hangman_web, :slack_app_secret, "SLACK_APP_SECRET"

config :hangman_web, :slack_message_token, "SLACK_MSG_TOKEN"
