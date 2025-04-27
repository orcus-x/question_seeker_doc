defmodule QuestionSeekerDoc.Services.S3Service do
  @moduledoc """
  Service for handling file uploads to S3 with proper region handling and no ACL issues.
  """

  @doc """
  Generates metadata for client direct upload to S3 (for frontend).
  """
  def meta(entry, uploads) do
    key = unique_filename(entry.client_name)

    {:ok, fields} =
      sign_form_upload(
        access_key_id(),
        secret_access_key(),
        bucket(),
        region(),
        key: key,
        content_type: entry.client_type,
        max_file_size: uploads[entry.upload_config].max_file_size,
        expires_in: :timer.hours(1)
      )

    %{
      uploader: "S3",
      key: key,
      url: s3_url(),
      fields: fields
    }
  end

  @doc """
  Uploads a file to S3 (used in backend). In tests, returns a mock URL.
  """
  def upload_file(file_path, file_name) do
    case Mix.env() do
      :test ->
        {:ok, "https://test-bucket.s3.amazonaws.com/uploads/#{file_name}"}

      _ ->
        s3_upload(file_path, file_name)
    end
  end

  ## Core private functions

  defp s3_upload(file_path, file_name) do
    key = unique_filename(file_name)
    file_binary = File.read!(file_path)

    s3_config = ExAws.Config.new(:s3, [
      region: region(),
      access_key_id: access_key_id(),
      secret_access_key: secret_access_key(),
      host: s3_host(),
      s3: [
        scheme: "https://",
        host: s3_host(),
        region: region()
      ]
    ])

    ExAws.S3.put_object(bucket(), key, file_binary,
      content_type: MIME.from_path(file_name) # ✅ no ACL here
    )
    |> ExAws.request(s3_config)
    |> case do
      {:ok, _} -> {:ok, "#{s3_url()}/#{key}"}
      {:error, {:http_error, 301, _}} -> handle_redirect(file_path, file_name)
      {:error, error} -> {:error, "S3 upload failed: #{inspect(error)}"}
    end
  end

  defp handle_redirect(file_path, file_name) do
    case get_bucket_region() do
      {:ok, actual_region} ->
        System.put_env("AWS_REGION", actual_region)
        s3_upload(file_path, file_name)

      {:error, error} ->
        {:error, "Failed to determine bucket region: #{inspect(error)}"}
    end
  end

  defp get_bucket_region do
    discovery_config = ExAws.Config.new(:s3, [
      region: "us-east-1",
      access_key_id: access_key_id(),
      secret_access_key: secret_access_key()
    ])

    ExAws.S3.head_bucket(bucket())
    |> ExAws.request(discovery_config)
    |> case do
      {:ok, %{headers: headers}} ->
        case Enum.find(headers, fn {k, _} -> String.downcase(k) == "x-amz-bucket-region" end) do
          {_, region} -> {:ok, region}
          nil -> {:error, "No region found in headers"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  ## Helpers

  defp unique_filename(filename) do
    uuid = UUID.uuid4()
    ext = Path.extname(filename)
    "uploads/#{uuid}#{ext}"
  end

  defp s3_host do
    case region() do
      "us-east-1" -> "s3.amazonaws.com"
      region -> "s3.#{region}.amazonaws.com"
    end
  end

  defp s3_url do
    case region() do
      "us-east-1" -> "https://#{bucket()}.s3.amazonaws.com"
      region -> "https://#{bucket()}.s3.#{region}.amazonaws.com"
    end
  end

  defp sign_form_upload(access_key_id, secret_access_key, bucket, region, opts) do
    key = opts[:key]
    content_type = opts[:content_type]
    max_file_size = opts[:max_file_size]
    expires_in = opts[:expires_in]

    datetime = DateTime.utc_now()
    date = Calendar.strftime(datetime, "%Y%m%d")
    amz_date = Calendar.strftime(datetime, "%Y%m%dT000000Z")

    credential = "#{access_key_id}/#{date}/#{region}/s3/aws4_request"

    policy = %{
      expiration: DateTime.add(datetime, expires_in) |> DateTime.to_iso8601(),
      conditions: [
        {"bucket", bucket},
        {"key", key},
        {"Content-Type", content_type},
        ["content-length-range", 0, max_file_size],
        {"x-amz-algorithm", "AWS4-HMAC-SHA256"},
        {"x-amz-credential", credential},
        {"x-amz-date", amz_date}
      ]
    }

    policy_encoded = policy |> Jason.encode!() |> Base.encode64()
    signature = sign_policy(policy_encoded, secret_access_key, date, region)

    fields = %{
      "key" => key,
      "Content-Type" => content_type,
      "Policy" => policy_encoded,
      "X-Amz-Algorithm" => "AWS4-HMAC-SHA256",
      "X-Amz-Credential" => credential,
      "X-Amz-Date" => amz_date,
      "X-Amz-Signature" => signature
    }

    {:ok, fields}
  end

  defp sign_policy(policy_encoded, secret, date, region) do
    k_date = :crypto.mac(:hmac, :sha256, "AWS4" <> secret, date)
    k_region = :crypto.mac(:hmac, :sha256, k_date, region)
    k_service = :crypto.mac(:hmac, :sha256, k_region, "s3")
    k_signing = :crypto.mac(:hmac, :sha256, k_service, "aws4_request")

    :crypto.mac(:hmac, :sha256, k_signing, policy_encoded)
    |> Base.encode16(case: :lower)
  end

  ## Configuration fetchers

  defp bucket do
    case Mix.env() do
      :test -> "test-bucket"
      _ -> System.get_env("AWS_S3_BUCKET") || raise "Missing AWS_S3_BUCKET environment variable"
    end
  end

  defp region do
    case Mix.env() do
      :test -> "us-east-1"
      _ -> System.get_env("AWS_REGION") || "us-east-1"
    end
  end

  defp access_key_id do
    case Mix.env() do
      :test -> "test-access-key"
      _ -> System.get_env("AWS_ACCESS_KEY_ID") || raise "Missing AWS_ACCESS_KEY_ID environment variable"
    end
  end

  defp secret_access_key do
    case Mix.env() do
      :test -> "test-secret-key"
      _ -> System.get_env("AWS_SECRET_ACCESS_KEY") || raise "Missing AWS_SECRET_ACCESS_KEY environment variable"
    end
  end
end
