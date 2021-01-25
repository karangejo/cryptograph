defmodule Cryptograph.Repo do
  use Ecto.Repo,
    otp_app: :cryptograph,
    adapter: Ecto.Adapters.Postgres
end
