defmodule HangmanWeb.Router do
  use HangmanWeb.Web, :router
  import HangmanWeb.Slack.RequestPlugs

  @slack_message_token Application.get_env(:hangman_web, :slack_message_token)

  pipeline :api,
    do: plug :accepts, ["json"]

  pipeline :slack_action do
    plug :parse_action_payload
    plug :verify_slack_token, @slack_message_token 
  end

  pipeline :slack_command do
    plug :parse_command_data
    plug :verify_slack_token, @slack_message_token
  end

  scope "/oauth", HangmanWeb do
    get "/authorized", OauthController, :authorized? 
  end

  scope "/hangman/message_actions" do
    pipe_through :slack_action
  
    post "/", HangmanWeb.Slack.ActionsController, :dispatch
  end

  scope "/hangman", HangmanWeb.Slack do
    pipe_through :slack_command

    post "/play", CommandsController, :start
    post "/guess", CommandsController, :guess
  end

  #  get "/*path", nil, nil
end
