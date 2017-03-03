defmodule HangmanWeb.Oauth.Slack.HTTP do
  @moduledoc """
  Module for use in production for Slack OAuth HTTP requests.
  """

  @client_id Application.get_env(:hangman_web, :slack_app_client_id)
  @client_secret Application.get_env(:hangman_web, :slack_app_secret)
  @hostname Application.get_env(:hangman_web, :hostname)

  @doc """
  Makes an external HTTPS `GET` call to Slack's `/api/oauth.access`
  endpoint to exchange a temporary OAuth access code for an API
  Access Token.

  See Slack's API documentation:
  https://api.slack.com/methods/oauth.access
  """
  @callback get_token(String.t) :: {:ok, String.t} | {:error, String.t}
  def get_token(code) do
    uri = "https://slack.com/api/oauth.access"
    id_string = "?client_id=" <> @client_id
    secret_string = "&client_secret=" <> @client_secret
    code_string = "&code=" <> code
    redirect_string = "&redirect_uri=https://" <> @hostname <> "/oauth/authorized"
    url = uri <> id_string <> secret_string <> code_string <> redirect_string

    with {:ok, resp_body} <- get_response(url),
         {:ok, body} <- Poison.decode(resp_body),
         {:ok, access_data} <- handle_response(body) do
           {:ok, access_data}
    else
      _ -> {:error, "Unable to validate code"}
    end
  end

  defp get_response(url),
    do: get_body(HTTPoison.get(url, [], []))

  defp get_body(%HTTPoison.Response{body: body}),
    do: {:ok, body}
  defp get_body(_),
    do: {:error, :bad_request}

  defp handle_response(%{"ok" => false, "error" => error}),
    do: {:error, error}
  defp handle_response(%{"ok" => true} = data),
    do: {:ok, Map.delete(data, "ok")}
  defp handle_response(_),
    do: {:error, "Unexpected Response"}
end
