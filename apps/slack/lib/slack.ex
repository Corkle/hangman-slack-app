defmodule Slack do
  @moduledoc """
  This module defines the `Slack` struct. Use `create/1` to
  convert webhook request data from Slack for parsing slash
  command and interactive message requests.
  """

  defstruct [action: nil, command: nil, text: nil,
             team: nil, channel: nil, user: nil, callback_id: nil,
             action_ts: nil, message_ts: nil, attachment_id: nil,
             token: nil, original_message: nil, response_url: nil]

  @doc """
  Converts incoming Slack HTTP request params to a `Slack` struct.
  `params` is expected to be a string-keyed map with either an
  `"actions"` or `"command"` key to determine the request type.

  Returns `{:ok, struct}` if params are valid format.
  Returns `{:error, message}` if params does not match the expected
  request data from Slack.
  """
  def create(%{"actions" => actions} = params),
    do: create_slack_action(actions, params)
  def create(%{"command" => actions} = params),
    do: convert_slack_data(%Slack{}, params) 
  def create(_),
    do: {:error, :invalid_slack_data}

  defp create_slack_action([action], params),
    do: convert_action(action, params) 
  defp create_slack_action([action | _], params),
    do: convert_action(action, params) 
  defp create_slack_action(_, params),
    do: {:error, :invalid_action_format}
    
  defp convert_action(action, params) do
    with {:ok, slack} <- put_action(%Slack{}, action),
         {:ok, slack} <- convert_slack_data(slack, params) do
           {:ok, slack}
    else
      {:error, error} -> {:error, error}
      _ -> {:error, :invalid_slack_data} 
    end
  end

  defp convert_slack_data(struct, params) do
    with {:ok, slack} <- convert_keys(struct, params),
         {:ok, slack} <- get_user(slack, params),
         {:ok, slack} <- get_team(slack, params),
         {:ok, slack} <- get_channel(slack, params) do
           {:ok, slack}
    else
      {:error, error} -> {:error, error}
      _ -> {:error, :invalid_slack_data}
    end
  end

  defp convert_keys(struct, params) do
    keys = Map.keys(Map.drop(struct, [:__struct__, :team, :user, :channel, :action]))
    slack =
      Enum.reduce(keys, struct, fn key, acc ->
        val = Map.get(params, Atom.to_string(key))
        Map.put(acc, key, val) 
      end)
    {:ok, slack}
  end

  defp put_action(struct, %{"name" => name, "value" => value}),
    do: {:ok, Map.put(struct, :action, %{name: name, value: value})}
  defp put_action(_, _),
    do: {:error, :invalid_action_format}

  defp get_user(struct, %{"user_id" => id, "user_name" => name}),
    do: put_user(struct, id, name)
  defp get_user(struct, %{"user" => %{"id" => id, "name" => name}}),
    do: put_user(struct, id, name)
  defp get_user(_, _),
    do: {:error, :invalid_user_format} 

  defp put_user(struct, id, name),
    do: {:ok, Map.put(struct, :user, %{id: id, name: name})}

  defp get_team(struct, %{"team_id" => id, "team_domain" => domain}),
    do: put_team(struct, id, domain)
  defp get_team(struct, %{"team" => %{"id" => id, "domain" => domain}}),
    do: put_team(struct, id, domain)
  defp get_team(_, _),
    do: {:error, :invalid_team_format} 

  defp put_team(struct, id, domain),
    do: {:ok, Map.put(struct, :team, %{id: id, domain: domain})}

  defp get_channel(struct, %{"channel_id" => id, "channel_name" => name}),
    do: put_channel(struct, id, name)
  defp get_channel(struct, %{"channel" => %{"id" => id, "name" => name}}),
    do: put_channel(struct, id, name)
  defp get_channel(_, _),
    do: {:error, :invalid_channel_format} 

  defp put_channel(struct, id, name),
    do: {:ok, Map.put(struct, :channel, %{id: id, name: name})}
end
