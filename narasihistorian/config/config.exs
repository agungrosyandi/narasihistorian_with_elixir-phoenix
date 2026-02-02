# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# ============================================================================
# GENERAL APPLICATION CONFIGURATION
# ============================================================================

import Config

config :narasihistorian,
  ecto_repos: [Narasihistorian.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint

config :narasihistorian, NarasihistorianWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: NarasihistorianWeb.ErrorHTML, json: NarasihistorianWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Narasihistorian.PubSub,
  live_view: [signing_salt: "oKnkPjqq"],

  # ... other config

  static: ~w(assets uploads fonts images favicon.ico robots.txt)

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.

config :narasihistorian, Narasihistorian.Mailer, adapter: Swoosh.Adapters.Local

# ============================================================================
# CONFIGURE ESBUILD (THE VERSION IS REQUIRED)
# ============================================================================

config :esbuild,
  version: "0.25.4",
  narasihistorian: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# ============================================================================
# CONFIGURE TAILWIND (THE VERSION IS REQUIRED)
# ============================================================================

config :tailwind,
  version: "4.1.12",
  narasihistorian: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# ============================================================================
# CONFIGURE ELIXIR LOGGER
# ============================================================================

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix

config :phoenix, :json_library, Jason

# ============================================================================
# OAUTH CONFIGURATION
# ============================================================================

config :ueberauth, Ueberauth,
  providers: [
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email profile",
         prompt: "select_account"
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# ============================================================================
# IMPORT ENVIRONMENT SPECIFIC CONFIG. THIS MUST REMAIN AT THE BOTTOM
# OF THIS FILE SO IT OVERRIDES THE CONFIGURATION DEFINED ABOVE
# ============================================================================

import_config "#{config_env()}.exs"
