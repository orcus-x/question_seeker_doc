# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :question_seeker_doc, QuestionSeekerDocWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "tlimIm015ljbsd6wwD7dvlxoJ2uCIHbjrEI4o2MgvRJMRl+l3sz5VS3MSu06BqxV",
  render_errors: [view: QuestionSeekerDocWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: QuestionSeekerDoc.PubSub,
  live_view: [signing_salt: "wBE/ySxl"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :question_seeker_doc,
  ecto_repos: [QuestionSeekerDoc.Repo]

config :cors_plug,
  origin: ["*"],  # Allow all origins (be careful with this in production)
  max_age: 86400

if Mix.env() in [:dev, :test] do
  config :dotenv, path: ".env"
end

# Configure HTTPoison
config :hackney, use_default_pool: false