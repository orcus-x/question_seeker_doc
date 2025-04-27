defmodule QuestionSeekerDocWeb.UploadController do
  use QuestionSeekerDocWeb, :controller
  alias QuestionSeekerDoc.Documents
  alias QuestionSeekerDoc.Documents.Upload
  alias QuestionSeekerDoc.Services.S3Service
  alias QuestionSeekerDoc.Services.TextractService
  alias QuestionSeekerDoc.Services.OpenAIService
  
  action_fallback QuestionSeekerDocWeb.FallbackController

  # GET /api/upload
  def index(conn, _params) do
    uploads = Documents.list_uploads()
    render(conn, "index.json", uploads: uploads)
  end
  
  # POST /api/upload
  def create(conn, %{"upload" => %Plug.Upload{content_type: content_type, filename: filename, path: path}}) do
    IO.puts("Received file: #{filename}, Content Type: #{content_type}")
    
    # 1. Create an upload record
    upload_attrs = %{
      "filename" => filename,
      "content_type" => content_type,
      "file_path" => path,
      "status" => "pending",
      "progress" => 0,
      "message" => "File uploaded, waiting for processing..."
    }
    
    case Documents.create_upload(upload_attrs) do
      {:ok, upload} ->
        # 2. Spawn a process to handle the document processing
        Task.start(fn -> process_document(upload) end)
        
        # Modify the response to include a placeholder for the document ID that will be created
        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.upload_path(conn, :show, upload.id))
        |> render("show_with_document_id.json", upload: upload)
      
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(QuestionSeekerDocWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end
  
  # Helper function to safely create questions
  defp create_questions_for_document(document, question_answers) do
    result = Enum.reduce(question_answers, [], fn %{"question" => question_text, "answer" => answer_text}, acc ->
      case Documents.create_question(%{
        "text" => question_text,
        "answer" => answer_text,
        "document_id" => document.id
      }) do
        {:ok, question} -> [question | acc]
        {:error, error} -> 
          IO.puts("Error creating question: #{inspect(error)}")
          acc
      end
    end)
    
    # Reverse the list to maintain original order
    Enum.reverse(result)
  end
  
  # Helper function to process the document asynchronously
  defp process_document(upload) do
    try do
      # Step 1: Update status to processing
      {:ok, upload} = Documents.update_upload(upload, %{
        "status" => "processing", 
        "progress" => 10,
        "message" => "Uploading document to secure storage..."
      })
      
      # Step 2: Save the file locally
      local_upload_dir = "uploads/"
      File.mkdir_p(local_upload_dir)
      
      destination_path = Path.join(local_upload_dir, upload.filename)
      File.cp(upload.file_path, destination_path)
      
      # Step 3: Upload file to S3 (or mock S3 in development)
      s3_result = S3Service.upload_file(upload.file_path, upload.filename)

      IO.puts("S3 upload result: #{inspect(s3_result)}")
      
      case s3_result do
        {:ok, file_url} ->
          # Update progress after S3 upload
          {:ok, upload} = Documents.update_upload(upload, %{
            "progress" => 30,
            "message" => "Document uploaded. Extracting text..."
          })
          
          # Step 4: Extract text using AWS Textract (or mock in development)
          textract_result = TextractService.extract_text(file_url)

          IO.puts("Textract result: #{inspect(textract_result)}")
          
          case textract_result do
            {:ok, extracted_text} ->
              # Update progress after text extraction
              {:ok, upload} = Documents.update_upload(upload, %{
                "progress" => 60,
                "message" => "Text extracted. Analyzing content..."
              })
              
              # Step 5: Create document record with the extracted text
              document_result = Documents.create_document(%{
                "file_name" => upload.filename,
                "file_url" => file_url,
                "extracted_text" => extracted_text,
                "status" => "completed"
              })
              
              case document_result do
                {:ok, document} ->
                  # Step 6: Associate document ID with the upload
                  {:ok, upload} = Documents.update_upload(upload, %{
                    "document_id" => document.id,
                    "progress" => 75,
                    "message" => "Generating intelligent questions from content..."
                  })
                  
                  # Step 7: Generate questions using OpenAI (or mock in development)
                  question_result = OpenAIService.extract_questions_and_answers(extracted_text)
                  
                  # Use our improved question creation function
                  case question_result do
                    {:ok, question_answers} ->
                      # Create questions using our helper function
                      created_questions = create_questions_for_document(document, question_answers)
                      successful_count = length(created_questions)
                      
                      # Step 8: Finalize the process
                      Documents.update_upload(upload, %{
                        "status" => "completed",
                        "progress" => 100,
                        "message" => "Document processed successfully with #{successful_count} questions and answers generated!"
                      })
                      
                    {:error, question_error} ->
                      # Create default questions if OpenAI fails
                      default_questions = [
                        %{"question" => "What is the main topic of this document?", "answer" => "This information couldn't be automatically determined."},
                        %{"question" => "Who is the intended audience?", "answer" => "This information couldn't be automatically determined."},
                        %{"question" => "What key points does this document cover?", "answer" => "This information couldn't be automatically determined."}
                      ]
                      
                      # Create questions using our helper function
                      created_questions = create_questions_for_document(document, default_questions)
                      successful_count = length(created_questions)
                      
                      # Still mark as completed but with a note
                      Documents.update_upload(upload, %{
                        "status" => "completed",
                        "progress" => 100,
                        "message" => "Document processed with #{successful_count} default questions. AI generation failed: #{question_error}"
                      })
                  end
                  
                {:error, changeset_error} ->
                  # Handle document creation failure
                  error_messages = Ecto.Changeset.traverse_errors(changeset_error, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {key, value}, acc ->
                      String.replace(acc, "%{#{key}}", to_string(value))
                    end)
                  end)
                  
                  error_string = inspect(error_messages)
                  
                  Documents.update_upload(upload, %{
                    "status" => "failed",
                    "progress" => 0,
                    "message" => "Failed to create document record: #{error_string}"
                  })
              end
              
            {:error, textract_error} ->
              # Handle Textract failure
              Documents.update_upload(upload, %{
                "status" => "failed",
                "progress" => 0,
                "message" => "Failed to extract text: #{textract_error}"
              })
          end
          
        {:error, s3_error} ->
          # Handle S3 upload failure
          Documents.update_upload(upload, %{
            "status" => "failed",
            "progress" => 0,
            "message" => "Failed to upload document: #{s3_error}"
          })
      end
      
    rescue
      e ->
        IO.puts("Error processing document: #{inspect(e)}")
        Documents.update_upload(upload, %{
          "status" => "failed",
          "progress" => 0,
          "message" => "Failed to process document: #{inspect(e)}"
        })
    catch
      kind, reason ->
        stack = __STACKTRACE__
        IO.puts("Caught #{kind} with reason: #{inspect(reason)}")
        IO.puts("Stack trace: #{inspect(stack)}")
        Documents.update_upload(upload, %{
          "status" => "failed",
          "progress" => 0,
          "message" => "Processing error: #{inspect(reason)}"
        })
    end
  end
  
  # GET /api/upload/:id
  def show(conn, %{"id" => id}) do
    upload = Documents.get_upload!(id)
    render(conn, "show.json", upload: upload)
  end
  
  # GET /api/documents/:id/status
  def status(conn, %{"id" => id}) do
    upload = Documents.get_upload!(id)
    
    conn
    |> put_status(:ok)
    |> json(%{
      id: upload.id,
      status: upload.status,
      progress: upload.progress || 0,
      message: upload.message || "",
      filename: upload.filename,
      content_type: upload.content_type,
      inserted_at: upload.inserted_at,
      updated_at: upload.updated_at
    })
  end
  
  # PUT /api/upload/:id
  def update(conn, %{"id" => id, "upload" => upload_params}) do
    upload = Documents.get_upload!(id)
    with {:ok, %Upload{} = updated_upload} <- Documents.update_upload(upload, upload_params) do
      render(conn, "show_with_document_id.json", upload: updated_upload)
    end
  end
  
  # DELETE /api/upload/:id
  def delete(conn, %{"id" => id}) do
    upload = Documents.get_upload!(id)
    with {:ok, %Upload{}} <- Documents.delete_upload(upload) do
      send_resp(conn, :no_content, "")
    end
  end
end