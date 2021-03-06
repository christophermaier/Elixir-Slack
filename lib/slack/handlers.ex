defmodule Slack.Handlers do
  @moduledoc """
  Defines `handle_slack/3` methods for keeping the `slack` argument in `Slack`
  up to date.
  """

  @doc """
  Pattern matches against messages and returns updated Slack state.
  """
  @spec handle_slack(Map, Map) :: {Symbol, Map}
  def handle_slack(%{type: "channel_created", channel: channel}, slack) do
    {:ok, put_in(slack, [:channels, channel.id], channel)}
  end

  Enum.map(["channel", "group"], fn (type) ->
    plural_atom = String.to_atom(type <> "s")

    def handle_slack(%{type: unquote(type <> "_joined"), channel: channel}, slack) do
      slack = put_in(slack, [unquote(plural_atom), channel.id, :members], channel.members)
      {:ok, put_in(slack, [unquote(plural_atom), channel.id, :is_member], true)}
    end
    def handle_slack(%{type: unquote(type <> "_left"), channel: channel}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel.id, :is_member], false)}
    end
    def handle_slack(%{type: unquote(type <> "_rename"), channel: channel}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel.id, :name], channel.name)}
    end
    def handle_slack(%{type: unquote(type <> "_archive"), channel: channel}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel, :is_archived], true)}
    end
    def handle_slack(%{type: unquote(type <> "_unarchive"), channel: channel}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel, :is_archived], false)}
    end
    def handle_slack(%{type: "message", subtype: unquote(type <> "_join"), channel: channel, user: user}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel, :members], [user | slack[unquote(plural_atom)][channel][:members]])}
    end
    def handle_slack(%{type: "message", subtype: unquote(type <> "_leave"), channel: channel, user: user}, slack) do
      {:ok, put_in(slack, [unquote(plural_atom), channel, :members], slack[unquote(plural_atom)][channel][:members] -- [user])}
    end
  end)

  def handle_slack(%{type: "team_rename", name: name}, slack) do
    {:ok, put_in(slack, [:team, :name], name)}
  end

  Enum.map(["team_join", "user_change"], fn (type) ->
    def handle_slack(%{type: unquote(type), user: user}, slack) do
      {:ok, put_in(slack, [:users, user.id], user)}
    end
  end)

  Enum.map(["bot_added", "bot_changed"], fn (type) ->
    def handle_slack(%{type: unquote(type), bot: bot}, slack) do
      {:ok, put_in(slack, [:bots, bot.id], bot)}
    end
  end)

  def handle_slack(%{type: _type}, slack) do
    {:ok, slack}
  end
end
