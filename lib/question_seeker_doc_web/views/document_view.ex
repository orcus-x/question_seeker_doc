defmodule QuestionSeekerDocWeb.DocumentView do
  use QuestionSeekerDocWeb, :view
  alias QuestionSeekerDocWeb.DocumentView
  alias QuestionSeekerDocWeb.QuestionView

  def render("index.json", %{documents: documents}) do
    %{data: render_many(documents, DocumentView, "document.json")}
  end

  def render("show.json", %{document: document}) do
    %{data: render_one(document, DocumentView, "document_with_questions.json")}
  end

  def render("document.json", %{document: document}) do
    %{
      id: document.id,
      name: document.file_name,
      fileUrl: document.file_url,
      extractedText: document.extracted_text || "",
      createdAt: document.inserted_at
    }
  end

  def render("document_with_questions.json", %{document: document}) do
    %{
      id: document.id,
      name: document.file_name,
      fileUrl: document.file_url,
      extractedText: document.extracted_text || "",
      createdAt: document.inserted_at,
      questions: render_many(document.questions || [], QuestionView, "question.json")
    }
  end
end
