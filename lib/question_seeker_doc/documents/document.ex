defmodule QuestionSeekerDoc.Documents.Document do
  use Ecto.Schema
  import Ecto.Changeset

  schema "documents" do
    field :file_name, :string
    field :file_url, :string
    field :extracted_text, :string
    field :status, :string, default: "completed"  # Add default status
    
    has_many :questions, QuestionSeekerDoc.Documents.Question

    timestamps()
  end

  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:file_name, :file_url, :extracted_text, :status])
    |> validate_required([:file_name, :file_url, :status])
  end
end