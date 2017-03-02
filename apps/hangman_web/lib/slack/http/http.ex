defmodule HangmanWeb.Slack.HTTP do
  @moduledoc """
  Module for production use for external HTTP requests
  using the HTTPoison library.  
  """

  @doc """
  Issues a `POST` request to the given url.
  `body` is JSON encoded and the request header set to
  Content-Type application/json.
  Returns `{:ok, response}` if successful, `{:error, reason}` otherwise.
  """
  @callback post_json(binary, term) ::
    {:ok, HTTPoison.Response.t | HTTPoison.AsyncResponse.t} | 
    {:error, HTTPoison.Error}
  def post_json(url, body),
    do: HTTPoison.post(url, Poison.encode!(body), [{"Content-Type", "application/json"}])

end

