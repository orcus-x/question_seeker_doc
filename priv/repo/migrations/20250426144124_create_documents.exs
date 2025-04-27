defmodule QuestionSeekerDoc.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: true) do
      add :file_name, :string, null: false
      add :file_url, :string, null: false
      add :extracted_text, :text
      add :status, :string, default: "completed"

      timestamps()
    end

    create index(:documents, [:status])
    create index(:documents, [:file_name])
  end
end