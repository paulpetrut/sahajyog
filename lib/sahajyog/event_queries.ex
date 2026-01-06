defmodule Sahajyog.EventQueries do
  @moduledoc """
  Query builder for events to reduce code duplication.
  Provides composable filters and unified query building.
  """

  import Ecto.Query
  alias Sahajyog.Events.Event

  @doc """
  Builds a base event query with optional filters.
  """
  def build_query(filters \\ %{}) do
    Event
    |> apply_filters(filters)
  end

  @doc """
  Applies filters to an event query.
  Supports: :status, :country, :city, :upcoming, :time_range, :month, :search, :user_level
  """
  def apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when is_binary(status) ->
        where(query, [e], e.status == ^status)

      {:country, country}, query when is_binary(country) and country != "" ->
        where(query, [e], e.country == ^country)

      {:city, city}, query when is_binary(city) and city != "" ->
        where(query, [e], e.city == ^city)

      {:upcoming, true}, query ->
        today = Date.utc_today()
        where(query, [e], e.event_date >= ^today)

      {:time_range, "1_month"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 30)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "3_months"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 90)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "6_months"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 180)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "1_year"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 365)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:month, month_str}, query when is_binary(month_str) and month_str != "" ->
        [year_s, month_s] = String.split(month_str, "-")
        year = String.to_integer(year_s)
        month = String.to_integer(month_s)

        where(
          query,
          [e],
          fragment("EXTRACT(YEAR FROM ?) = ?", e.event_date, ^year) and
            fragment("EXTRACT(MONTH FROM ?) = ?", e.event_date, ^month)
        )

      {:search, search}, query when is_binary(search) and search != "" ->
        search_term = "%#{String.downcase(search)}%"

        where(
          query,
          [e],
          fragment(
            "LOWER(?) LIKE ? OR LOWER(?) LIKE ? OR LOWER(?) LIKE ?",
            e.title,
            ^search_term,
            e.city,
            ^search_term,
            e.country,
            ^search_term
          )
        )

      _, query ->
        query
    end)
    |> maybe_apply_level_filter(filters[:user_level])
  end

  @doc """
  Applies level filter to query.
  """
  def maybe_apply_level_filter(query, nil), do: filter_by_level(query, "Level1")
  def maybe_apply_level_filter(query, level), do: filter_by_level(query, level)

  defp filter_by_level(query, level) do
    case level do
      "Level1" -> where(query, [e], e.level == "Level1")
      "Level2" -> where(query, [e], e.level in ["Level1", "Level2"])
      "Level3" -> where(query, [e], e.level in ["Level1", "Level2", "Level3"])
      _ -> where(query, [e], e.level == "Level1")
    end
  end

  @doc """
  Builds a query for events visible to a specific user.
  Includes public events and events where user is owner or team member.
  """
  def build_user_visible_query(nil, user_level) do
    # No user, only show public events
    today = Date.utc_today()
    allowed_levels = get_allowed_levels(user_level)

    Event
    |> where(
      [e],
      e.status == "public" and e.event_date >= ^today and
        (e.level in ^allowed_levels or is_nil(e.level))
    )
  end

  def build_user_visible_query(user_id, user_level) do
    today = Date.utc_today()
    allowed_levels = get_allowed_levels(user_level)

    Event
    |> join(:left, [e], tm in Sahajyog.Events.EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> where(
      [e, tm],
      # Public events matching level and date criteria
      # OR events user owns or is team member of
      (e.status == "public" and e.event_date >= ^today and
         (e.level in ^allowed_levels or is_nil(e.level))) or
        e.user_id == ^user_id or not is_nil(tm.id)
    )
  end

  @doc """
  Builds a query for user's personal events (owner or team member).
  Does NOT include public events just because they are public.
  """
  def build_my_events_query(nil) do
    # No user, return empty query
    Event
    |> where([e], false)
  end

  def build_my_events_query(user_id) do
    Event
    |> join(:left, [e], tm in Sahajyog.Events.EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> join(:left, [e, tm], a in Sahajyog.Events.EventAttendance,
      on: a.event_id == e.id and a.user_id == ^user_id and a.status == "attending"
    )
    |> where(
      [e, tm, a],
      e.user_id == ^user_id or not is_nil(tm.id) or not is_nil(a.id)
    )
  end

  @doc """
  Builds a query for past public events.
  """
  def build_past_public_query(user_level) do
    today = Date.utc_today()

    Event
    |> where([e], e.status == "public" and e.event_date < ^today)
    |> filter_by_level(user_level)
  end

  @doc """
  Builds a query for upcoming public events.
  """
  def build_upcoming_public_query(user_level) do
    today = Date.utc_today()

    Event
    |> where([e], e.status == "public" and e.event_date >= ^today)
    |> filter_by_level(user_level)
  end

  @doc """
  Builds a query for publicly accessible events (for Welcome page).
  """
  def build_publicly_accessible_query do
    today = Date.utc_today()

    Event
    |> where(
      [e],
      e.status == "public" and e.event_date >= ^today and e.is_publicly_accessible == true
    )
  end

  @doc """
  Builds a query for filter options (countries, cities, months).
  """
  def build_filter_options_query(user_id, user_level, type) do
    today = Date.utc_today()

    case type do
      "my_events" ->
        build_my_events_filter_query(user_id)

      "past" ->
        build_past_events_filter_query(user_level, today)

      _ ->
        build_default_filter_query(user_id, user_level, today)
    end
  end

  defp build_my_events_filter_query(nil) do
    # No user, return empty query
    Event
    |> where([e], false)
  end

  defp build_my_events_filter_query(user_id) do
    Event
    |> join(:left, [e], tm in Sahajyog.Events.EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> join(:left, [e, tm], a in Sahajyog.Events.EventAttendance,
      on: a.event_id == e.id and a.user_id == ^user_id and a.status == "attending"
    )
    |> where(
      [e, tm, a],
      e.user_id == ^user_id or not is_nil(tm.id) or not is_nil(a.id)
    )
  end

  defp build_past_events_filter_query(user_level, today) do
    Event
    |> where([e], e.status == "public" and e.event_date < ^today)
    |> filter_by_level(user_level)
  end

  defp build_default_filter_query(nil, user_level, today) do
    # No user, only show public events
    allowed_levels = get_allowed_levels(user_level)

    Event
    |> where(
      [e],
      e.status == "public" and e.event_date >= ^today and
        (e.level in ^allowed_levels or is_nil(e.level))
    )
  end

  defp build_default_filter_query(user_id, user_level, today) do
    # For users, show public events OR events they own/are team members of
    # We need to avoid dynamic expressions with `or` at non-top-level
    allowed_levels = get_allowed_levels(user_level)

    Event
    |> join(:left, [e], tm in Sahajyog.Events.EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> where(
      [e, tm],
      # Public events matching level and date criteria
      # OR events user owns or is team member of
      (e.status == "public" and e.event_date >= ^today and
         (e.level in ^allowed_levels or is_nil(e.level))) or
        e.user_id == ^user_id or not is_nil(tm.id)
    )
  end

  @doc """
  Applies pagination to a query.
  """
  def apply_pagination(query, page, per_page) do
    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end

  @doc """
  Applies ordering to a query.
  """
  def apply_ordering(query, direction \\ :asc) do
    order_by(query, [e], {^direction, e.event_date})
  end

  @doc """
  Applies preloading to a query.
  """
  def apply_preload(query) do
    preload(query, [:user, team_members: :user])
  end

  # Private helpers

  defp get_allowed_levels("Level1"), do: ["Level1"]
  defp get_allowed_levels("Level2"), do: ["Level1", "Level2"]
  defp get_allowed_levels("Level3"), do: ["Level1", "Level2", "Level3"]
  defp get_allowed_levels(_), do: ["Level1"]

  # ============================================================================
  # List Functions - Execute queries and return results
  # ============================================================================

  alias Sahajyog.Repo

  @doc """
  Lists events with optional filters.
  """
  def list_events(filters \\ %{}) do
    build_query(filters)
    |> apply_ordering()
    |> apply_preload()
    |> Repo.all()
  end

  @doc """
  Lists events with pagination.
  Returns {events, total_count}
  """
  def list_events_paginated(filters \\ %{}, page \\ 1, per_page \\ 12) do
    base_query = build_query(filters)
    total = Repo.aggregate(base_query, :count, :id)

    events =
      base_query
      |> apply_ordering()
      |> apply_pagination(page, per_page)
      |> apply_preload()
      |> Repo.all()

    {events, total}
  end

  @doc """
  Lists upcoming public events.
  """
  def list_upcoming_events(opts \\ []) do
    user_level = Keyword.get(opts, :user_level, "Level1")

    build_upcoming_public_query(user_level)
    |> apply_ordering()
    |> apply_preload()
    |> Repo.all()
  end

  @doc """
  Lists publicly accessible events (for Welcome page).
  """
  def list_publicly_accessible_events do
    build_publicly_accessible_query()
    |> apply_ordering()
    |> apply_preload()
    |> Repo.all()
  end

  @doc """
  Lists past public events.
  """
  def list_past_public_events(opts \\ []) do
    user_level = Keyword.get(opts, :user_level, "Level1")

    build_past_public_query(user_level)
    |> apply_ordering(:desc)
    |> apply_preload()
    |> Repo.all()
  end

  @doc """
  Lists past public events with pagination.
  Returns {events, total_count}
  """
  def list_past_public_events_paginated(filters \\ %{}, page \\ 1, per_page \\ 12) do
    user_level = Map.get(filters, :user_level, "Level1")
    # For past events, we need to handle time_range differently (backwards from today)
    filters_without_time_range = Map.delete(filters, :time_range)
    base_query = build_past_public_query(user_level) |> apply_filters(filters_without_time_range)

    # Apply time_range filter for past events (backwards from today)
    base_query =
      case Map.get(filters, :time_range) do
        "1_month" ->
          from_date = Date.add(Date.utc_today(), -30)
          where(base_query, [e], e.event_date >= ^from_date)

        "3_months" ->
          from_date = Date.add(Date.utc_today(), -90)
          where(base_query, [e], e.event_date >= ^from_date)

        "6_months" ->
          from_date = Date.add(Date.utc_today(), -180)
          where(base_query, [e], e.event_date >= ^from_date)

        "1_year" ->
          from_date = Date.add(Date.utc_today(), -365)
          where(base_query, [e], e.event_date >= ^from_date)

        _ ->
          base_query
      end

    total = Repo.aggregate(base_query, :count, :id)

    events =
      base_query
      |> apply_ordering(:desc)
      |> apply_pagination(page, per_page)
      |> apply_preload()
      |> Repo.all()

    {events, total}
  end

  @doc """
  Gets filter options (countries, cities, months) for events.
  """
  def get_event_filter_options(user_id, user_level, type) do
    # Build base query for filtering - we need to execute separate queries
    # because the base query may have joins that complicate distinct selects
    base_event_ids = get_filter_event_ids(user_id, user_level, type)

    if base_event_ids == [] do
      %{countries: [], cities: [], months: []}
    else
      countries =
        Event
        |> where([e], e.id in ^base_event_ids)
        |> where([e], not is_nil(e.country) and e.country != "")
        |> select([e], e.country)
        |> distinct(true)
        |> order_by([e], asc: e.country)
        |> Repo.all()

      cities =
        Event
        |> where([e], e.id in ^base_event_ids)
        |> where([e], not is_nil(e.city) and e.city != "")
        |> select([e], e.city)
        |> distinct(true)
        |> order_by([e], asc: e.city)
        |> Repo.all()

      months =
        Event
        |> where([e], e.id in ^base_event_ids)
        |> where([e], not is_nil(e.event_date))
        |> select([e], fragment("to_char(?, 'YYYY-MM')", e.event_date))
        |> distinct(true)
        |> Repo.all()
        |> Enum.sort(:desc)

      %{countries: countries, cities: cities, months: months}
    end
  end

  defp get_filter_event_ids(user_id, user_level, type) do
    query = build_filter_options_query(user_id, user_level, type)

    query
    |> select([e], e.id)
    |> distinct(true)
    |> Repo.all()
  end

  @doc """
  Lists events visible to a specific user.
  """
  def list_events_for_user(user_id, opts \\ []) do
    user_level = Keyword.get(opts, :user_level, "Level1")

    build_user_visible_query(user_id, user_level)
    |> apply_ordering()
    |> apply_preload()
    |> distinct([e], e.id)
    |> Repo.all()
  end

  @doc """
  Lists events for user with pagination.
  Returns {events, total_count}
  """
  def list_events_for_user_paginated(user_id, filters \\ %{}, page \\ 1, per_page \\ 12) do
    user_level = Map.get(filters, :user_level, "Level1")

    base_query =
      build_user_visible_query(user_id, user_level)
      |> apply_filters(filters)
      |> distinct([e], e.id)

    total = Repo.aggregate(base_query, :count, :id)

    events =
      base_query
      |> apply_ordering()
      |> apply_pagination(page, per_page)
      |> apply_preload()
      |> Repo.all()

    {events, total}
  end

  @doc """
  Lists user's personal events (owner, team member, or attending).
  """
  def list_my_events(user_id) do
    build_my_events_query(user_id)
    |> apply_ordering()
    |> apply_preload()
    |> distinct([e], e.id)
    |> Repo.all()
  end

  @doc """
  Lists user's personal events with pagination.
  Returns {events, total_count}
  """
  def list_my_events_paginated(user_id, page \\ 1, per_page \\ 12) do
    base_query =
      build_my_events_query(user_id)
      |> distinct([e], e.id)

    total = Repo.aggregate(base_query, :count, :id)

    events =
      base_query
      |> apply_ordering()
      |> apply_pagination(page, per_page)
      |> apply_preload()
      |> Repo.all()

    {events, total}
  end
end
