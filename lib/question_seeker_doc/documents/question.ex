defmodule QuestionSeekerDoc.Documents.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :text, :string
    field :answer, :string
    belongs_to :document, QuestionSeekerDoc.Documents.Document

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :answer, :document_id])
    |> validate_required([:text, :document_id])
    |> foreign_key_constraint(:document_id)
  end
end