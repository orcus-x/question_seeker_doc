defmodule QuestionSeekerDoc.Services.OpenAIClient do
    @moduledoc """
    Client for interacting with OpenAI API to extract questions and answers from documents.
    Optimized version that supports both traditional extraction and combined question-answer extraction.
    Includes robust error handling, timeouts, and model selection based on task complexity.
    """
    require Logger
    alias HTTPoison
  
    @openai_api_url "https://api.openai.com/v1/chat/completions"
    
    # Default timeouts for different operations (in milliseconds)
    @timeout_combined_extraction 20000 # 20 seconds
    @timeout_questions_extraction 15000 # 15 seconds
    @timeout_answers_generation 25000 # 25 seconds 
    @timeout_single_answer 30000 # 30 seconds
    @timeout_generate_qa 20000 # 20 seconds
    
    @doc """
    Extracts both questions and their corresponding answers from a document in a single API call.
    This is more efficient than extracting questions first and then finding answers separately.
    Returns a list of question-answer pair objects.
    """
    def extract_questions_and_answers_together(document_text) do
      system_prompt = """
      You are an intelligent assistant that identifies both questions and their answers in documents.
      For each question found in the document, also extract the answer that appears after the question.
      If a question doesn't have an answer in the document, indicate that with "[NO_ANSWER]".
      Format your response as a valid JSON array of objects, where each object has "question" and "answer" fields.
      """
      
      user_prompt = """
      Extract all questions AND their answers from the following document:
      
      #{document_text}
      
      Instructions:
      1. Include ONLY questions explicitly written in the document.
      2. For each question, extract the answer text that follows it, up until the next question or paragraph break.
      3. If no answer is found for a question in the document, mark it as "[NO_ANSWER]".
      
      Return your response in this JSON format:
      [
        {"question": "First question?", "answer": "Answer text to first question."},
        {"question": "Second question?", "answer": "[NO_ANSWER]"},
        ...
      ]
      
      If no questions are found, return an empty array: []
      """
      
      # Use GPT-4 for better accuracy in complex extraction
      options = [
        model: "gpt-4",
        timeout: @timeout_combined_extraction
      ]
      
      Logger.debug("Extracting questions and answers together from document")
      case call_openai_api_with_options(system_prompt, user_prompt, options) do
        {:ok, response} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          
          case Jason.decode(content) do
            {:ok, qa_pairs} when is_list(qa_pairs) -> {:ok, qa_pairs}
            {:error, error} ->
              Logger.error("Failed to parse OpenAI response as JSON: #{inspect(error)}, content: #{content}")
              {:error, "Failed to parse AI-extracted questions and answers"}
          end
          
        {:error, reason} -> {:error, reason}
      end
    end
    
    @doc """
    Extracts questions present in a document using OpenAI.
    Returns a list of questions found in the document.
    """
    def extract_questions_from_document(document_text) do
      system_prompt = """
      You are an intelligent assistant that identifies questions present in documents.
      Extract only the actual questions that appear in the document - do not generate new questions.
      Format your response as a valid JSON array of strings, where each string is a question.
      """
      
      user_prompt = """
      Extract all questions from the following document. Return ONLY questions that are explicitly written in the document:
      
      #{document_text}
      
      Return your response as a JSON array of question strings:
      ["First question from document?", "Second question from document?", ...]
      
      If no questions are found, return an empty array: []
      """
      
      # Use faster model for simple extraction
      options = [
        model: "gpt-3.5-turbo",
        timeout: @timeout_questions_extraction
      ]
      
      Logger.debug("Extracting questions from document using traditional method")
      case call_openai_api_with_options(system_prompt, user_prompt, options) do
        {:ok, response} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          
          case Jason.decode(content) do
            {:ok, questions} when is_list(questions) -> {:ok, questions}
            {:error, error} ->
              Logger.error("Failed to parse OpenAI response as JSON: #{inspect(error)}, content: #{content}")
              {:error, "Failed to parse AI-extracted questions"}
          end
          
        {:error, reason} -> {:error, reason}
      end
    end
    
    @doc """
    Generates questions and answers based on document text when no questions are found.
    Returns a list of question and answer pairs.
    """
    def generate_questions_and_answers(document_text) do
      system_prompt = """
      You are an intelligent assistant that generates relevant questions and answers based on document content.
      Generate 3-5 insightful questions that someone might ask about this document, and provide detailed, accurate answers for each question.
      Focus on the most important information in the document.
      Format your response as a valid JSON array containing objects with "question" and "answer" fields.
      """
      
      user_prompt = """
      Based on the following document, generate 3-5 insightful questions and provide detailed answers:
      
      #{document_text}
      
      Generate questions that:
      1. Cover the most important information in the document
      2. Would be helpful for someone trying to understand the document
      3. Address different aspects of the document content
      
      Return your response in the following JSON format:
      [
        {
          "question": "First question here?",
          "answer": "Detailed answer to the first question here."
        },
        ... additional questions and answers ...
      ]
      """
      
      # Use advanced model for creative generation
      options = [
        model: "gpt-4",
        timeout: @timeout_generate_qa
      ]
      
      Logger.debug("Generating questions and answers for document with no questions")
      case call_openai_api_with_options(system_prompt, user_prompt, options) do
        {:ok, response} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          
          case Jason.decode(content) do
            {:ok, decoded} when is_list(decoded) -> {:ok, decoded}
            {:ok, _} -> 
              Logger.error("OpenAI response not in expected format: #{content}")
              {:error, "Unexpected response format from AI"}
            {:error, error} ->
              Logger.error("Failed to parse OpenAI response as JSON: #{inspect(error)}, content: #{content}")
              {:error, "Failed to parse AI-generated content"}
          end
          
        {:error, reason} -> {:error, reason}
      end
    end
    
    @doc """
    Generates answers for a list of questions without answers in the document.
    Returns a list of answers in the same order as the questions.
    """
    def generate_answers_for_questions(questions, document_text) do
      system_prompt = """
      You are an intelligent assistant that generates accurate answers to questions.
      Use the provided context if relevant, or your general knowledge if not.
      Provide concise yet informative answers for each question.
      Format your response as a valid JSON array of strings, where each string is an answer.
      """
      
      questions_formatted = Enum.map_join(questions, "\n", fn q -> "- #{q}" end)
      
      user_prompt = """
      Context: #{document_text}
      
      Please provide answers to the following questions:
      #{questions_formatted}
      
      Instructions:
      1. Base your answers on the provided context when possible
      2. Keep answers concise but informative
      3. If the document doesn't contain information for a question, provide a reasonable answer
      
      Return your response as a JSON array of answers in the same order as the questions:
      ["Answer to first question", "Answer to second question", ...]
      """
      
      # Use advanced model for high-quality answers
      options = [
        model: "gpt-4",
        timeout: @timeout_answers_generation
      ]
      
      Logger.debug("Generating answers for #{length(questions)} questions")
      case call_openai_api_with_options(system_prompt, user_prompt, options) do
        {:ok, response} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          
          case Jason.decode(content) do
            {:ok, answers} when is_list(answers) -> {:ok, answers}
            {:ok, _} -> 
              Logger.error("OpenAI response not in expected format: #{content}")
              {:error, "Unexpected response format from AI"}
            {:error, error} ->
              Logger.error("Failed to parse OpenAI response as JSON: #{inspect(error)}, content: #{content}")
              {:error, "Failed to parse AI-generated content"}
          end
          
        {:error, reason} -> {:error, reason}
      end
    end
    
    @doc """
    Generates an answer for a single question.
    This is used as a fallback when batch answer generation fails.
    Returns a single answer string.
    """
    def generate_single_answer(question, document_text) do
      system_prompt = """
      You are an intelligent assistant that provides concise, accurate answers to questions.
      """
      
      user_prompt = """
      Based on the following context, please answer this question:
      
      Context: #{document_text}
      
      Question: #{question}
      
      Provide a direct, concise answer.
      """
      
      # Use faster model for individual questions
      options = [
        model: "gpt-3.5-turbo",
        timeout: @timeout_single_answer
      ]
      
      Logger.debug("Generating single answer for question: #{String.slice(question, 0, 50)}...")
      case call_openai_api_with_options(system_prompt, user_prompt, options) do
        {:ok, response} ->
          content = response["choices"] |> List.first() |> Map.get("message") |> Map.get("content")
          {:ok, content}
          
        {:error, reason} -> 
          Logger.error("Failed to generate single AI answer: #{inspect(reason)}")
          {:error, reason}
      end
    end
    
    @doc """
    Makes the API call to OpenAI's chat completions endpoint with specified options.
    Handles timeouts, retries, and error cases.
    """
    def call_openai_api_with_options(system_prompt, user_prompt, options) do
      api_key = System.get_env("OPENAI_API_KEY")
      
      if is_nil(api_key) or api_key == "" do
        Logger.error("OpenAI API key not configured in environment variables")
        {:error, "OpenAI API key not configured"}
      else
        headers = [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{api_key}"}
        ]
        
        # Extract model from options or use default
        model = Keyword.get(options, :model, "gpt-4")
        
        payload = %{
          "model" => model,
          "messages" => [
            %{"role" => "system", "content" => system_prompt},
            %{"role" => "user", "content" => user_prompt}
          ],
          "temperature" => 0.7
        }
        
        # Extract timeout from options
        timeout = Keyword.get(options, :timeout, 10000)
        
        # Set both connect_timeout and recv_timeout
        http_options = [
          timeout: timeout,
          recv_timeout: timeout,
          connect_timeout: min(5000, timeout)  # Connect timeout shouldn't be too long
        ]
        
        # Number of retries
        max_retries = Keyword.get(options, :retries, 1)
        
        Logger.debug("Making OpenAI API call with model: #{model}, timeout: #{timeout}ms")
        
        # Try the API call with retries
        do_api_call(payload, headers, http_options, max_retries)
      end
    end
    
    # Helper function to handle API calls with retries
    defp do_api_call(payload, headers, http_options, retries_left) do
      case HTTPoison.post(@openai_api_url, Jason.encode!(payload), headers, http_options) do
        {:ok, %{status_code: 200, body: body}} ->
          {:ok, Jason.decode!(body)}
          
        {:ok, %{status_code: status, body: body}} when status >= 500 and retries_left > 0 ->
          # Server error, retry
          Logger.warning("OpenAI API server error (#{status}), retrying... (#{retries_left} attempts left)")
          Process.sleep(1000) # Wait 1 second before retry
          do_api_call(payload, headers, http_options, retries_left - 1)
          
        {:ok, %{status_code: status, body: body}} ->
          # Client error or out of retries
          Logger.error("OpenAI API error: status=#{status}, body=#{body}")
          {:error, "OpenAI API error: #{status}"}
          
        {:error, %{reason: :timeout}} when retries_left > 0 ->
          # Timeout, retry
          Logger.warning("OpenAI API timeout, retrying... (#{retries_left} attempts left)")
          Process.sleep(1000) # Wait 1 second before retry
          do_api_call(payload, headers, http_options, retries_left - 1)
          
        {:error, %{reason: reason}} ->
          Logger.error("OpenAI API request failed: #{inspect(reason)}")
          {:error, "OpenAI API request failed: #{inspect(reason)}"}
      end
    end
  end