defmodule HangmanWeb.Router do
  use HangmanWeb.Web, :router

  pipeline :api,
    do: plug :accepts, ["json"]

  scope "/oauth", HangmanWeb do
    get "/authorized", OauthController, :authorized? 
  end

  scope "/hangman", HangmanWeb.Slack do
    post "/message_actions", ActionController, :dispatch
    post "/*path", CommandController, :dispatch
  end

  #  get "/*path", nil, nil
end
