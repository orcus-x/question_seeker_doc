defmodule QuestionSeekerDoc.Repo do
  use Ecto.Repo,
    otp_app: :question_seeker_doc,
    adapter: Ecto.Adapters.Postgres
end
