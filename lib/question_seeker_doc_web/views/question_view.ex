defmodule QuestionSeekerDocWeb.QuestionView do
  use QuestionSeekerDocWeb, :view
  alias QuestionSeekerDocWeb.QuestionView

  def render("index.json", %{questions: questions}) do
    %{data: render_many(questions, QuestionView, "question.json")}
  end

  def render("show.json", %{question: question}) do
    %{data: render_one(question, QuestionView, "question.json")}
  end

  def render("question.json", %{question: question}) do
    %{
      id: question.id,
      text: question.text,
      answer: question.answer,
      documentId: question.document_id,
      createdAt: question.inserted_at
    }
  end
end