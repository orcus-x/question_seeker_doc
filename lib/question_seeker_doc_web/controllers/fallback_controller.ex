defmodule QuestionSeekerDocWeb.FallbackController do
  use QuestionSeekerDocWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(QuestionSeekerDocWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(QuestionSeekerDocWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(QuestionSeekerDocWeb.ErrorView)
    |> render("error.json", message: reason)
  end
end
