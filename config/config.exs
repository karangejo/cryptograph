# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :cryptograph,
  ecto_repos: [Cryptograph.Repo]

# Configures the endpoint
config :cryptograph, CryptographWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/qBtGXniDF40+BAsdlB8yMIepTT2LZqeH+QDnLhs5eThOGr6LiVxM/lgKfhz8Ci7",
  render_errors: [view: CryptographWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cryptograph.PubSub,
  live_view: [signing_salt: "5g89v9hc"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
