defmodule QuestionSeekerDocWeb.Router do
  use QuestionSeekerDocWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["*"]
  end

  scope "/api", QuestionSeekerDocWeb do
    pipe_through :api

    # Document routes
    resources "/documents", DocumentController, only: [:index, :show]

    # Question routes
    resources "/questions", QuestionController, only: [:index, :show]
    get "/documents/:document_id/questions", QuestionController, :document_questions

    # Upload routes
    resources "/upload", UploadController, only: [:create, :show]
    get "/documents/:id/status", UploadController, :status
  end

  # Enables LiveDashboard only for development
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: QuestionSeekerDocWeb.Telemetry
    end
  end
end
