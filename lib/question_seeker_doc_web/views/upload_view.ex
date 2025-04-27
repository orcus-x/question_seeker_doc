defmodule QuestionSeekerDocWeb.UploadView do
  use QuestionSeekerDocWeb, :view
  alias QuestionSeekerDocWeb.UploadView
  
  def render("index.json", %{uploads: uploads}) do
    %{data: render_many(uploads, UploadView, "upload.json")}
  end
  
  def render("show.json", %{upload: upload}) do
    %{data: render_one(upload, UploadView, "upload.json")}
  end
  
  def render("show_with_document_id.json", %{upload: upload}) do
    %{data: render_one(upload, UploadView, "upload_with_document.json")}
  end
  
  def render("upload.json", %{upload: upload}) do
    %{
      id: upload.id,
      filename: upload.filename,
      filePath: upload.file_path,
      contentType: upload.content_type,
      createdAt: upload.inserted_at
    }
  end
  
  def render("upload_with_document.json", %{upload: upload}) do
    %{
      id: upload.id,
      filename: upload.filename,
      filePath: upload.file_path,
      contentType: upload.content_type,
      createdAt: upload.inserted_at,
      documentId: upload.document_id  # Include the document ID in the response
    }
  end
end