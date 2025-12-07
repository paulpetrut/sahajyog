defmodule Sahajyog.Admin do
  @moduledoc """
  The Admin context for managing access codes and other administrative tasks.
  """

  import Ecto.Query, warn: false
  alias Sahajyog.Repo
  alias Sahajyog.Admin.AccessCode

  @doc """
  Lists all access codes.
  """
  def list_access_codes do
    Repo.all(
      from ac in AccessCode, preload: [:event, :created_by], order_by: [desc: ac.inserted_at]
    )
  end

  @doc """
  Gets an access code by its code string.
  """
  def get_access_code_by_code(code) when is_binary(code) do
    Repo.get_by(AccessCode, code: code)
  end

  def get_access_code_by_code(_), do: nil

  @doc """
  Creates an access code.
  """
  def create_access_code(attrs \\ %{}) do
    %AccessCode{}
    |> AccessCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an access code.
  """
  def delete_access_code(%AccessCode{} = access_code) do
    Repo.delete(access_code)
  end

  @doc """
  Increments usage count for an access code.
  """
  def increment_usage(access_code) do
    from(ac in AccessCode, where: ac.id == ^access_code.id)
    |> Repo.update_all(inc: [usage_count: 1])
  end
end
