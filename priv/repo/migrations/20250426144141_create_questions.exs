defmodule QuestionSeekerDoc.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: true) do
      add :text, :text, null: false
      add :document_id, references(:documents, on_delete: :delete_all), null: false
      add :answer, :text

      timestamps()
    end

    create index(:questions, [:document_id])
  end
end