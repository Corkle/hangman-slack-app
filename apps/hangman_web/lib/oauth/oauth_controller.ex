defmodule HangmanWeb.OauthController do
  use HangmanWeb.Web, :controller
  @slack_oauth_api Application.get_env(:hangman_web, :slack_oauth_api)

  def authorized?(conn, %{"error" => "access_denied"}) do
    conn
    |> put_status(400)
    |> text("Hangman needs your permission to integrate with your Slack team. Please use the Add to Slack button to grant the requested authorization.")
  end

  def authorized?(conn, %{"code" => code}) do
    valid_token?(@slack_oauth_api.get_token(code), conn)
  end

  def authorized?(conn, _) do
    conn
    |> put_status(400)
    |> text("bad request")
  end

  defp valid_token?({:error, error}, conn) do 
    conn
    |> put_status(400)
    |> text("Slack did not recognize the access code generated from your authorization approval. Please use the Add to Slack button to grant authorization again.")
  end

  defp valid_token?({:ok, _token}, conn) do
    #TODO: Save token
    conn
    |> put_status(200)
    |> text("Success! Hangman has been added to your Slack team. Try out the /playhangman command from the channels you have authroized. You may now close this page.")
  end
end

