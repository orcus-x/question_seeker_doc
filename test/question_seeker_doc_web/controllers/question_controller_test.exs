defmodule QuestionSeekerDocWeb.QuestionControllerTest do
  use QuestionSeekerDocWeb.ConnCase

  alias QuestionSeekerDoc.Documents
  alias QuestionSeekerDoc.Documents.Question

  setup %{conn: conn} do
    {:ok, document} = Documents.create_document(%{
      file_name: "test_document.pdf",
      status: "completed"
    })

    {:ok, question} = Documents.create_question(%{
      text: "This is a test question?",
      document_id: document.id
    })

    {:ok, _question2} = Documents.create_question(%{
      text: "Here is another question?",
      document_id: document.id
    })

    %{conn: conn, document: document, question: question}
  end

  describe "index" do
    test "lists all questions", %{conn: conn} do
      conn = get(conn, Routes.question_path(conn, :index))
      assert json_response(conn, 200)["data"] |> length() >= 2
    end
  end

  describe "show" do
    test "gets a specific question", %{conn: conn, question: question} do
      conn = get(conn, Routes.question_path(conn, :show, question))
      assert json_response(conn, 200)["data"]["id"] == question.id
    end
  end

  describe "document_questions" do
    test "gets questions for a specific document", %{conn: conn, document: document} do
      conn = get(conn, Routes.question_path(conn, :document_questions, document))
      assert json_response(conn, 200)["data"] |> length() == 2
    end
  end
end
