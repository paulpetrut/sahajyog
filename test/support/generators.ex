defmodule Sahajyog.Generators do
  @moduledoc """
  StreamData generators for property-based testing.
  """

  use ExUnitProperties

  alias Sahajyog.Accounts.User
  alias Sahajyog.Content.Video

  @doc """
  Generates a user with a random level (Level1, Level2, Level3) or nil for unauthenticated.
  """
  def user_or_nil do
    one_of([
      constant(nil),
      user_with_level()
    ])
  end

  @doc """
  Generates a user struct with a random level.
  """
  def user_with_level do
    gen all(level <- member_of(["Level1", "Level2", "Level3"])) do
      %User{
        id: System.unique_integer([:positive]),
        email: "user#{System.unique_integer()}@example.com",
        level: level
      }
    end
  end

  @doc """
  Generates a user level string.
  """
  def user_level do
    member_of(["Level1", "Level2", "Level3"])
  end

  @doc """
  Generates a video category.
  """
  def video_category do
    member_of(["Welcome", "Getting Started", "Advanced Topics", "Excerpts"])
  end

  @doc """
  Generates a video struct with a random category.
  """
  def video do
    gen all(
          category <- video_category(),
          title <- string(:alphanumeric, min_length: 1, max_length: 50)
        ) do
      %Video{
        id: System.unique_integer([:positive]),
        title: title,
        url: "https://youtube.com/watch?v=#{System.unique_integer()}",
        category: category,
        provider: "youtube"
      }
    end
  end

  @doc """
  Generates a list of videos with various categories.
  """
  def video_list do
    list_of(video(), min_length: 0, max_length: 20)
  end

  @doc """
  Generates a pool size between 1 and 31.
  """
  def pool_size do
    integer(1..31)
  end

  @doc """
  Generates a pool size between 1 and a given max.
  """
  def pool_size(max) when max >= 1 do
    integer(1..min(max, 31))
  end

  @doc """
  Generates a valid pool position (1-31).
  """
  def pool_position do
    integer(1..31)
  end
end
