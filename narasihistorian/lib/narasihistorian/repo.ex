defmodule Narasihistorian.Repo do
  use Ecto.Repo,
    otp_app: :narasihistorian,
    adapter: Ecto.Adapters.Postgres
end
