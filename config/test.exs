use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :question_seeker_doc, QuestionSeekerDocWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :question_seeker_doc, QuestionSeekerDoc.Repo,
  username: "phoenix",
  password: "password",
  database: "question_seeker_doc_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
