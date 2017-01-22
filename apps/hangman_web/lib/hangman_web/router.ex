defmodule HangmanWeb.Router do
  use HangmanWeb.Web, :router

  pipeline :api,
    do: plug :accepts, ["json"]

  scope "/oauth", HangmanWeb do
    get "/authorized", OauthController, :authorized? 
  end

  #  get "/*path", nil, nil
end
