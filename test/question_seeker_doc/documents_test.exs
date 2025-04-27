defmodule QuestionSeekerDoc.DocumentsTest do
  use QuestionSeekerDoc.DataCase

  alias QuestionSeekerDoc.Documents

  describe "documents" do
    alias QuestionSeekerDoc.Documents.Document

    @valid_attrs %{extracted_text: "some extracted_text", file_name: "some file_name", file_url: "some file_url", status: "some status"}
    @update_attrs %{extracted_text: "some updated extracted_text", file_name: "some updated file_name", file_url: "some updated file_url", status: "some updated status"}
    @invalid_attrs %{extracted_text: nil, file_name: nil, file_url: nil, status: nil}

    def document_fixture(attrs \\ %{}) do
      {:ok, document} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Documents.create_document()

      document
    end

    test "list_documents/0 returns all documents" do
      document = document_fixture()
      assert Documents.list_documents() == [document]
    end

    test "get_document!/1 returns the document with given id" do
      document = document_fixture()
      assert Documents.get_document!(document.id) == document
    end

    test "create_document/1 with valid data creates a document" do
      assert {:ok, %Document{} = document} = Documents.create_document(@valid_attrs)
      assert document.extracted_text == "some extracted_text"
      assert document.file_name == "some file_name"
      assert document.file_url == "some file_url"
      assert document.status == "some status"
    end

    test "create_document/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Documents.create_document(@invalid_attrs)
    end

    test "update_document/2 with valid data updates the document" do
      document = document_fixture()
      assert {:ok, %Document{} = document} = Documents.update_document(document, @update_attrs)
      assert document.extracted_text == "some updated extracted_text"
      assert document.file_name == "some updated file_name"
      assert document.file_url == "some updated file_url"
      assert document.status == "some updated status"
    end

    test "update_document/2 with invalid data returns error changeset" do
      document = document_fixture()
      assert {:error, %Ecto.Changeset{}} = Documents.update_document(document, @invalid_attrs)
      assert document == Documents.get_document!(document.id)
    end

    test "delete_document/1 deletes the document" do
      document = document_fixture()
      assert {:ok, %Document{}} = Documents.delete_document(document)
      assert_raise Ecto.NoResultsError, fn -> Documents.get_document!(document.id) end
    end

    test "change_document/1 returns a document changeset" do
      document = document_fixture()
      assert %Ecto.Changeset{} = Documents.change_document(document)
    end
  end

  describe "questions" do
    alias QuestionSeekerDoc.Documents.Question

    @valid_attrs %{text: "some text"}
    @update_attrs %{text: "some updated text"}
    @invalid_attrs %{text: nil}

    def question_fixture(attrs \\ %{}) do
      {:ok, question} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Documents.create_question()

      question
    end

    test "list_questions/0 returns all questions" do
      question = question_fixture()
      assert Documents.list_questions() == [question]
    end

    test "get_question!/1 returns the question with given id" do
      question = question_fixture()
      assert Documents.get_question!(question.id) == question
    end

    test "create_question/1 with valid data creates a question" do
      assert {:ok, %Question{} = question} = Documents.create_question(@valid_attrs)
      assert question.text == "some text"
    end

    test "create_question/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Documents.create_question(@invalid_attrs)
    end

    test "update_question/2 with valid data updates the question" do
      question = question_fixture()
      assert {:ok, %Question{} = question} = Documents.update_question(question, @update_attrs)
      assert question.text == "some updated text"
    end

    test "update_question/2 with invalid data returns error changeset" do
      question = question_fixture()
      assert {:error, %Ecto.Changeset{}} = Documents.update_question(question, @invalid_attrs)
      assert question == Documents.get_question!(question.id)
    end

    test "delete_question/1 deletes the question" do
      question = question_fixture()
      assert {:ok, %Question{}} = Documents.delete_question(question)
      assert_raise Ecto.NoResultsError, fn -> Documents.get_question!(question.id) end
    end

    test "change_question/1 returns a question changeset" do
      question = question_fixture()
      assert %Ecto.Changeset{} = Documents.change_question(question)
    end
  end

  describe "uploads" do
    alias QuestionSeekerDoc.Documents.Upload

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def upload_fixture(attrs \\ %{}) do
      {:ok, upload} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Documents.create_upload()

      upload
    end

    test "list_uploads/0 returns all uploads" do
      upload = upload_fixture()
      assert Documents.list_uploads() == [upload]
    end

    test "get_upload!/1 returns the upload with given id" do
      upload = upload_fixture()
      assert Documents.get_upload!(upload.id) == upload
    end

    test "create_upload/1 with valid data creates a upload" do
      assert {:ok, %Upload{} = upload} = Documents.create_upload(@valid_attrs)
    end

    test "create_upload/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Documents.create_upload(@invalid_attrs)
    end

    test "update_upload/2 with valid data updates the upload" do
      upload = upload_fixture()
      assert {:ok, %Upload{} = upload} = Documents.update_upload(upload, @update_attrs)
    end

    test "update_upload/2 with invalid data returns error changeset" do
      upload = upload_fixture()
      assert {:error, %Ecto.Changeset{}} = Documents.update_upload(upload, @invalid_attrs)
      assert upload == Documents.get_upload!(upload.id)
    end

    test "delete_upload/1 deletes the upload" do
      upload = upload_fixture()
      assert {:ok, %Upload{}} = Documents.delete_upload(upload)
      assert_raise Ecto.NoResultsError, fn -> Documents.get_upload!(upload.id) end
    end

    test "change_upload/1 returns a upload changeset" do
      upload = upload_fixture()
      assert %Ecto.Changeset{} = Documents.change_upload(upload)
    end
  end
end
