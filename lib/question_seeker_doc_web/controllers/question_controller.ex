defmodule QuestionSeekerDocWeb.QuestionController do
  use QuestionSeekerDocWeb, :controller

  alias QuestionSeekerDoc.Documents
  alias QuestionSeekerDoc.Documents.Question

  action_fallback QuestionSeekerDocWeb.FallbackController

  def index(conn, _params) do
    questions = Documents.list_questions()
    render(conn, "index.json", questions: questions)
  end

  def show(conn, %{"id" => id}) do
    question = Documents.get_question!(id)
    render(conn, "show.json", question: question)
  end

  def document_questions(conn, %{"document_id" => document_id}) do
    questions = Documents.list_questions_for_document(document_id)
    render(conn, "index.json", questions: questions)
  end
end
