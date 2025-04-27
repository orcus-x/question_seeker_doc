defmodule QuestionSeekerDoc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      QuestionSeekerDocWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: QuestionSeekerDoc.PubSub},
      # Start the Endpoint (http/https)
      QuestionSeekerDocWeb.Endpoint,
      # Start a worker by calling: QuestionSeekerDoc.Worker.start_link(arg)
      # {QuestionSeekerDoc.Worker, arg}
      {QuestionSeekerDoc.Repo, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QuestionSeekerDoc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    QuestionSeekerDocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
