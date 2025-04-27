defmodule QuestionSeekerDocWeb.DocumentControllerTest do
  use QuestionSeekerDocWeb.ConnCase

  alias QuestionSeekerDoc.Documents
  alias QuestionSeekerDoc.Documents.Document

  @create_attrs %{
    file_name: "test_document.pdf",
    file_url: "https://example.com/test_document.pdf",
    extracted_text: "This is a test document with a question? Here is another question?",
    status: "completed"
  }

  setup %{conn: conn} do
    {:ok, document} = Documents.create_document(@create_attrs)

    {:ok, _question1} = Documents.create_question(%{
      text: "This is a test document with a question?",
      document_id: document.id
    })

    {:ok, _question2} = Documents.create_question(%{
      text: "Here is another question?",
      document_id: document.id
    })

    %{conn: conn, document: document}
  end

  describe "index" do
    test "lists all documents", %{conn: conn} do
      conn = get(conn, Routes.document_path(conn, :index))
      assert json_response(conn, 200)["data"] |> length() >= 1
    end
  end

  describe "show" do
    test "gets a specific document with questions", %{conn: conn, document: document} do
      conn = get(conn, Routes.document_path(conn, :show, document))
      response = json_response(conn, 200)["data"]

      assert response["id"] == document.id
      assert response["file_name"] == document.file_name
      assert length(response["questions"]) == 2
    end
  end
end
