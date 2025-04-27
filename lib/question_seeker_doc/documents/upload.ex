defmodule QuestionSeekerDoc.Documents.Upload do
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "uploads" do
    field :filename, :string
    field :content_type, :string
    field :file_path, :string
    field :status, :string, default: "pending"
    field :progress, :integer, default: 0
    field :message, :string
    field :document_id, :integer
    timestamps()
  end
  
  def changeset(upload, attrs) do
    upload
    |> cast(attrs, [:filename, :content_type, :file_path, :status, :progress, :message, :document_id])
    |> validate_required([:filename, :content_type, :file_path])
  end
end