defmodule QuestionSeekerDocWeb.DocumentController do
  use QuestionSeekerDocWeb, :controller

  alias QuestionSeekerDoc.Documents
  alias QuestionSeekerDoc.Documents.Document

  action_fallback QuestionSeekerDocWeb.FallbackController

  def index(conn, _params) do
    documents = Documents.list_documents()
    render(conn, "index.json", documents: documents)
  end

  def show(conn, %{"id" => id}) do
    document = Documents.get_document_with_questions!(id)
    render(conn, "show.json", document: document)
  end
end
