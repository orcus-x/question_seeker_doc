defmodule QuestionSeekerDoc.Documents do
  @moduledoc """
  The Documents context.
  """

  import Ecto.Query, warn: false
  alias QuestionSeekerDoc.Repo

  alias QuestionSeekerDoc.Documents.Document
  alias QuestionSeekerDoc.Documents.Question
  alias QuestionSeekerDoc.Documents.Upload

  @doc """
  Returns the list of documents.

  ## Examples

      iex> list_documents()
      [%Document{}, ...]

  """
  def list_documents do
    Repo.all(Document)
  end

  @doc """
  Gets a single document.

  Raises `Ecto.NoResultsError` if the Document does not exist.

  ## Examples

      iex> get_document!(123)
      %Document{}

      iex> get_document!(456)
      ** (Ecto.NoResultsError)

  """
  def get_document!(id), do: Repo.get!(Document, id)

  @doc """
  Gets a document with preloaded questions.
  """
  def get_document_with_questions!(id) do
    Document
    |> Repo.get!(id)
    |> Repo.preload(:questions)
  end

  @doc """
  Creates a document.

  ## Examples

      iex> create_document(%{field: value})
      {:ok, %Document{}}

      iex> create_document(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document.

  ## Examples

      iex> update_document(document, %{field: new_value})
      {:ok, %Document{}}

      iex> update_document(document, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a document.

  ## Examples

      iex> delete_document(document)
      {:ok, %Document{}}

      iex> delete_document(document)
      {:error, %Ecto.Changeset{}}

  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking document changes.

  ## Examples

      iex> change_document(document)
      %Ecto.Changeset{data: %Document{}}

  """
  def change_document(%Document{} = document, attrs \\ %{}) do
    Document.changeset(document, attrs)
  end

  @doc """
  Returns the list of questions.

  ## Examples

      iex> list_questions()
      [%Question{}, ...]

  """
  def list_questions do
    Repo.all(Question)
  end

  @doc """
  Gets a single question.

  Raises `Ecto.NoResultsError` if the Question does not exist.

  ## Examples

      iex> get_question!(123)
      %Question{}

      iex> get_question!(456)
      ** (Ecto.NoResultsError)

  """
  def get_question!(id), do: Repo.get!(Question, id)

  @doc """
  Creates a question.

  ## Examples

      iex> create_question(%{field: value})
      {:ok, %Question{}}

      iex> create_question(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_question(attrs \\ %{}) do
    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a question.

  ## Examples

      iex> update_question(question, %{field: new_value})
      {:ok, %Question{}}

      iex> update_question(question, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a question.

  ## Examples

      iex> delete_question(question)
      {:ok, %Question{}}

      iex> delete_question(question)
      {:error, %Ecto.Changeset{}}

  """
  def delete_question(%Question{} = question) do
    Repo.delete(question)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking question changes.

  ## Examples

      iex> change_question(question)
      %Ecto.Changeset{data: %Question{}}

  """
  def change_question(%Question{} = question, attrs \\ %{}) do
    Question.changeset(question, attrs)
  end

  @doc """
  Returns the list of questions for a specific document.
  """
  def list_questions_for_document(document_id) do
    Question
    |> where([q], q.document_id == ^document_id)
    |> Repo.all()
  end

  @doc """
  Returns the list of uploads.

  ## Examples

      iex> list_uploads()
      [%Upload{}, ...]

  """
  def list_uploads do
    Repo.all(Upload)
  end

  @doc """
  Gets a single upload.

  Raises if the Upload does not exist.

  ## Examples

      iex> get_upload!(123)
      %Upload{}
  """
  def get_upload!(id), do: Repo.get!(Upload, id)

  @doc """
  Creates an upload.

  ## Examples

      iex> create_upload(%{filename: "file.pdf", content_type: "application/pdf", path: "/tmp/path"})
      {:ok, %Upload{}}

      iex> create_upload(%{filename: "file.pdf", content_type: "application/pdf", path: "/invalid/path"})
      {:error, "Failed to save the uploaded file"}
  """
  def create_upload(%{"filename" => filename, "content_type" => content_type, "file_path" => path}) do
    upload_dir = "uploads/"
    File.mkdir_p(upload_dir)  # Ensure the directory exists
  
    destination_path = Path.join(upload_dir, filename)
  
    case File.cp(path, destination_path) do
      :ok ->
        upload_params = %{
          filename: filename,
          content_type: content_type,
          file_path: destination_path
        }
  
        %Upload{}
        |> Upload.changeset(upload_params)
        |> Repo.insert()
  
      {:error, reason} ->
        IO.puts("Error copying file: #{reason}")
        {:error, "Failed to save the uploaded file"}
    end
  end

  @doc """
  Updates an upload.

  ## Examples

      iex> update_upload(upload, %{filename: "new_file.pdf"})
      {:ok, %Upload{}}

      iex> update_upload(upload, %{filename: "invalid_file.pdf"})
      {:error, %Ecto.Changeset{}}
  """
  def update_upload(%Upload{} = upload, attrs) do
    upload
    |> Upload.changeset(attrs)
    |> Repo.update()
  end


  @doc """
  Deletes a Upload.

  ## Examples

      iex> delete_upload(upload)
      {:ok, %Upload{}}

      iex> delete_upload(upload)
      {:error, %Ecto.Changeset{}}
  """
  def delete_upload(%Upload{} = upload) do
    Repo.delete(upload)
  end

  @doc """
  Returns a data structure for tracking upload changes.

  ## Examples

      iex> change_upload(upload)
      %Ecto.Changeset{data: %Upload{}}
  """
  def change_upload(%Upload{} = upload, attrs \\ %{}) do
    Upload.changeset(upload, attrs)
  end

end
