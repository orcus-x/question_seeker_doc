defmodule QuestionSeekerDoc.Repo.Migrations.CreateUploads do
  use Ecto.Migration

  def change do
    create table(:uploads, primary_key: true) do
      add :filename, :string, null: false
      add :content_type, :string, null: false
      add :file_path, :string, null: false
      add :status, :string, default: "pending"
      add :progress, :integer, default: 0
      add :message, :text
      add :document_id, references(:documents, on_delete: :nilify_all), null: true

      timestamps()
    end

    create index(:uploads, [:status])
    create index(:uploads, [:document_id])
  end
end