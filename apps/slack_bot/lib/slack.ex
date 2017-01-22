defmodule SlackBot.Slack do
  use Slack

  def start_link(token), do:
    Slack.Bot.start_link(__MODULE__, [], token)

  def handle_connect(_slack, state) do
    IO.puts("SLACK CONNECTED")
    {:ok, state}
  end

  # def handle_event(message = %{type: "message"}, slack, state), do:
  #   handle_message(process_message(message, slack, state), slack)

  # Catch-all does not respond to events
  def handle_event(_, _, state), do:
    {:ok, state}





  defp handle_message({:no_reply, _, state}, slack) do
    IO.puts("NO_REPLY")
    {:ok, state}
  end

  defp handle_message({channel, text, state}, slack) do
    IO.puts("TO #{channel}: #{text}")
    send_message(text, channel, slack)
    {:ok, state}
  end

  defp process_message(%{channel: "D" <> _} = message, slack, state), do:
    handle_direct_message(message, slack, state)

  defp process_message(%{text: "<@U3QRANNP4>" <> _, channel: ch}, _slack, state), do:
    {ch, "I will end you...", state}

  defp process_message(message, _slack, state) do
    IO.inspect(message)
    {:no_reply, nil, state}
  end

  defp handle_direct_message(message, _slack, state) do
    IO.puts("DM")
    # res = Slack.Web.Chat.post_message(message.channel, "Shhhh....", params)
   #  IO.inspect(res)
    {message.channel, "You said: #{message.text}", state}
  end
end
