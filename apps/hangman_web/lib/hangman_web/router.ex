defmodule HangmanWeb.Router do
  use HangmanWeb.Web, :router

  pipeline :api,
    do: plug :accepts, ["json"]

  scope "/oauth", HangmanWeb do
    get "/authorized", OauthController, :authorized? 
  end

  scope "/hangman", HangmanWeb do
    post "/play", ActionsController, :start
    post "/message_actions", ActionsController, :dispatch
  end

  #  get "/*path", nil, nil
end
