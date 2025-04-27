defmodule QuestionSeekerDoc.Services.TextractService do
  @moduledoc """
  Service for extracting text from PDF documents in S3 using AWS Textract (asynchronous).
  """

  alias ExAws.Textract.S3Object

  @region "eu-west-2"
  @poll_interval 2_000  # 2 seconds between polls
  @max_attempts 30      # Poll up to 30 times (60 seconds total)

  @doc """
  Extract text from a PDF stored in S3 using AWS Textract asynchronous job.
  """
  def extract_text(file_url) do
    with {:ok, {bucket, key}} <- parse_s3_url(file_url),
         {:ok, job_id} <- start_text_detection(bucket, key),
         {:ok, blocks} <- poll_for_completion(job_id) do
      {:ok, extract_text_from_blocks(blocks)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Parse S3 URL
  defp parse_s3_url(url) do
    case URI.parse(url) do
      %URI{host: host, path: path} when is_binary(host) and is_binary(path) ->
        [bucket | _] = String.split(host, ".s3")
        key = String.trim_leading(path, "/")
        {:ok, {bucket, key}}

      _ ->
        {:error, "Invalid S3 URL format"}
    end
  end

  # Start Textract asynchronous text detection
  defp start_text_detection(bucket, key) do
    s3_object = %{
      "DocumentLocation" => %{
        "S3Object" => %{
          "Bucket" => bucket,
          "Name" => key
        }
      }
    }

    ExAws.Operation.JSON.new(:textract, %{
      http_method: :post,
      path: "/",
      data: s3_object,
      headers: [
        {"content-type", "application/x-amz-json-1.1"},
        {"x-amz-target", "Textract.StartDocumentTextDetection"}
      ]
    })
    |> ExAws.request(region: @region)
    |> case do
      {:ok, %{"JobId" => job_id}} -> {:ok, job_id}
      error -> {:error, "Failed to start text detection: #{inspect(error)}"}
    end
  end

  # Poll for job completion
  defp poll_for_completion(job_id, attempt \\ 0)

  defp poll_for_completion(_job_id, attempt) when attempt > @max_attempts do
    {:error, "Textract job polling timeout"}
  end

  defp poll_for_completion(job_id, attempt) do
    Process.sleep(@poll_interval)

    ExAws.Operation.JSON.new(:textract, %{
      http_method: :post,
      path: "/",
      data: %{"JobId" => job_id},
      headers: [
        {"content-type", "application/x-amz-json-1.1"},
        {"x-amz-target", "Textract.GetDocumentTextDetection"}
      ]
    })
    |> ExAws.request(region: @region)
    |> case do
      {:ok, %{"JobStatus" => "SUCCEEDED", "Blocks" => blocks}} ->
        {:ok, blocks}

      {:ok, %{"JobStatus" => "IN_PROGRESS"}} ->
        poll_for_completion(job_id, attempt + 1)

      {:ok, %{"JobStatus" => "FAILED"}} ->
        {:error, "Textract job failed"}

      error ->
        {:error, "Unexpected response while polling: #{inspect(error)}"}
    end
  end

  # Extract lines of text from Blocks
  defp extract_text_from_blocks(blocks) do
    blocks
    |> Enum.filter(fn block -> block["BlockType"] == "LINE" end)
    |> Enum.map(fn block -> block["Text"] end)
    |> Enum.join("\n")
  end
end
