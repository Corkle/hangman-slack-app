defmodule HangmanWeb.Router do
  use HangmanWeb.Web, :router
  import HangmanWeb.SlackPlugs

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

  scope "/hangman/message_actions", HangmanWeb do
    pipe_through :slack_action

    forward "/", Plugs.ActionRouter
  end

  scope "/hangman", HangmanWeb do
    pipe_through :slack_command

    post "/play", ActionsController, :start
    post "/guess", ActionsController, :guess
   
  end

  #  get "/*path", nil, nil
end
