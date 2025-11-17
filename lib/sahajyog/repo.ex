defmodule Sahajyog.Repo do
  use Ecto.Repo,
    otp_app: :sahajyog,
    adapter: Ecto.Adapters.Postgres
end
