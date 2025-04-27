defmodule QuestionSeekerDoc.Services.OpenAIService do
  @moduledoc """
  Service for extracting questions and answers from document text using OpenAI.
  - Uses AI to identify both questions and answers in the document in a single operation
  - Generates AI answers for questions that exist in the document but lack answers
  - Falls back to traditional extraction when combined approach fails
  - Includes robust error handling and fallback mechanisms
  """
  require Logger
  alias QuestionSeekerDoc.Services.OpenAIClient

  # Cache for recently processed documents to avoid redundant API calls
  @doc false
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Extracts questions and answers from document text using AI assistance.
  Uses an optimized approach that extracts both questions and answers in a single operation.
  """
  def extract_questions_and_answers(document_text) do
    Logger.debug("Starting optimized document extraction with AI assistance...")
    
    # Check cache first
    case get_cached_result(document_text) do
      nil ->
        # Not in cache, proceed with extraction
        process_document(document_text)
        
      cached_result ->
        Logger.info("Using cached result for document")
        cached_result
    end
  end
  
  # Process document with combined extraction approach, with fallbacks
  defp process_document(document_text) do
    # Step 1: Try to extract both questions and answers together
    result = extract_questions_with_answers(document_text)
    
    # Cache and return the result
    cache_result(document_text, result)
    result
  end
  
  # Extract both questions and answers together in a single API call
  defp extract_questions_with_answers(document_text) do
    case OpenAIClient.extract_questions_and_answers_together(document_text) do
      {:ok, qa_pairs} ->
        if Enum.empty?(qa_pairs) do
          Logger.info("No questions identified in document.")
          
          # If no questions found, try to generate some based on document content
          case generate_questions_when_none_found(document_text) do
            {:ok, generated_qa_pairs} -> 
              Logger.info("Generated #{length(generated_qa_pairs)} questions and answers.")
              {:ok, generated_qa_pairs}
            {:error, _} -> 
              {:ok, []}
          end
        else
          Logger.info("Found #{length(qa_pairs)} questions in the document.")
          
          # Filter out questions with no answers from the document
          {questions_with_answers, questions_needing_answers} = 
            Enum.split_with(qa_pairs, fn %{"answer" => answer} -> 
              answer != nil && answer != "[NO_ANSWER]"
            end)
          
          if Enum.empty?(questions_needing_answers) do
            # All questions have answers from the document
            Logger.info("All questions have answers from the document.")
            {:ok, qa_pairs}
          else
            # Generate AI answers for questions without document answers
            questions_for_ai = Enum.map(questions_needing_answers, fn %{"question" => q} -> q end)
            Logger.info("Generating AI answers for #{length(questions_for_ai)} questions.")
            
            case generate_ai_answers_for_questions(questions_for_ai, document_text) do
              {:ok, ai_answers} ->
                # Create a map of questions to AI answers for easy lookup
                ai_answer_map = Map.new(Enum.zip(questions_for_ai, ai_answers))
                
                # Combine document answers with AI-generated answers
                updated_qa_pairs = 
                  Enum.map(qa_pairs, fn qa_pair = %{"question" => question, "answer" => answer} ->
                    if answer == nil || answer == "[NO_ANSWER]" do
                      %{qa_pair | "answer" => Map.get(ai_answer_map, question, "No answer available.")}
                    else
                      qa_pair
                    end
                  end)
                
                {:ok, updated_qa_pairs}
                
              {:error, reason} ->
                Logger.error("Failed to generate AI answers: #{inspect(reason)}")
                # Try individual questions as a fallback
                updated_qa_pairs = 
                  Enum.map(qa_pairs, fn qa_pair = %{"question" => question, "answer" => answer} ->
                    if answer == nil || answer == "[NO_ANSWER]" do
                      # Try to generate an answer for each individual question
                      case generate_single_ai_answer(question, document_text) do
                        {:ok, ai_answer} -> %{qa_pair | "answer" => ai_answer}
                        {:error, _} -> %{qa_pair | "answer" => "No answer available."}
                      end
                    else
                      qa_pair
                    end
                  end)
                
                {:ok, updated_qa_pairs}
            end
          end
        end
        
      {:error, reason} ->
        Logger.error("Failed to extract questions and answers from document: #{inspect(reason)}")
        
        # Fallback to traditional extraction if combined approach fails
        Logger.info("Falling back to traditional question extraction...")
        traditional_extraction(document_text)
    end
  end
  
  # Generate questions and answers when none are found in the document
  defp generate_questions_when_none_found(document_text) do
    Logger.info("No questions found in document, generating relevant questions...")
    OpenAIClient.generate_questions_and_answers(document_text)
  end
  
  # Generate AI answers for questions without document answers
  defp generate_ai_answers_for_questions(questions, document_text) do
    OpenAIClient.generate_answers_for_questions(questions, document_text)
  end
  
  # Generate an AI answer for a single question when the batch process fails
  defp generate_single_ai_answer(question, document_text) do
    OpenAIClient.generate_single_answer(question, document_text)
  end
  
  # Traditional extraction method as fallback
  defp traditional_extraction(document_text) do
    # Step 1: Use OpenAI to identify questions in the document
    case OpenAIClient.extract_questions_from_document(document_text) do
      {:ok, questions} ->
        if Enum.empty?(questions) do
          Logger.info("No questions identified in document with traditional method.")
          
          # Try to generate some questions based on document content
          generate_questions_when_none_found(document_text)
        else
          Logger.info("Found #{length(questions)} questions in the document with traditional method.")
          
          # Step 2: For each question, try to find answers in the document
          questions_with_answers = find_answers_in_document(questions, document_text)
          
          # Step 3: For questions without answers, generate them with AI
          questions_needing_answers = 
            Enum.filter(questions_with_answers, fn {_q, a} -> a == nil end)
            |> Enum.map(fn {q, _} -> q end)
          
          if Enum.empty?(questions_needing_answers) do
            # All questions have answers from the document
            format_output(questions_with_answers)
          else
            # Generate AI answers for questions without document answers
            Logger.info("Generating AI answers for #{length(questions_needing_answers)} questions.")
            
            case generate_ai_answers_for_questions(questions_needing_answers, document_text) do
              {:ok, ai_answers} ->
                # Merge document answers with AI-generated answers
                ai_answer_map = Map.new(Enum.zip(questions_needing_answers, ai_answers))
                
                final_qa_pairs = 
                  Enum.map(questions_with_answers, fn {question, answer} ->
                    if answer == nil do
                      {question, Map.get(ai_answer_map, question, "No answer available.")}
                    else
                      {question, answer}
                    end
                  end)
                
                format_output(final_qa_pairs)
                
              {:error, reason} ->
                Logger.error("Failed to generate AI answers: #{inspect(reason)}")
                # Try individual questions
                final_qa_pairs = 
                  Enum.map(questions_with_answers, fn {question, answer} ->
                    if answer == nil do
                      case generate_single_ai_answer(question, document_text) do
                        {:ok, ai_answer} -> {question, ai_answer}
                        {:error, _} -> {question, "No answer available."}
                      end
                    else
                      {question, answer}
                    end
                  end)
                
                format_output(final_qa_pairs)
            end
          end
        end
        
      {:error, reason} ->
        Logger.error("Failed to identify questions in document: #{inspect(reason)}")
        {:error, "Failed to process document: #{inspect(reason)}"}
    end
  end
  
  # Try to find answers for each question in the document text
  defp find_answers_in_document(questions, document_text) do
    Enum.map(questions, fn question ->
      answer = find_answer_for_question(question, document_text)
      {question, answer}
    end)
  end
  
  # Search for an answer to a specific question in the document
  defp find_answer_for_question(question, document_text) do
    # First try regex-based extraction to find exact question match
    case find_answer_regex(question, document_text) do
      nil ->
        # If regex fails, try more flexible approach
        find_answer_flexible(question, document_text)
      answer ->
        answer
    end
  end
  
  # Use regex to find exact question match and extract answer
  defp find_answer_regex(question, document_text) do
    clean_question = String.trim(question)
    pattern = Regex.escape(clean_question) <> "\\s*([^\\?]+)(?:\\?|\\n|$)"
    
    case Regex.run(~r/#{pattern}/i, document_text) do
      [_, answer] -> 
        String.trim(answer)
      _ -> 
        nil
    end
  end
  
  # Use more flexible approach to find answer
  defp find_answer_flexible(question, document_text) do
    # Try to find an answer in the text that follows the question
    clean_question = String.trim(question)
    parts = String.split(document_text, clean_question, parts: 2)
    
    if length(parts) > 1 do
      # Question found in document, look for answer after it
      potential_answer_text = Enum.at(parts, 1)
      
      # Look for the answer in the text following the question until the next question or paragraph
      answer = extract_potential_answer(potential_answer_text)
      
      if answer && String.trim(answer) != "" do
        String.trim(answer)
      else
        nil
      end
    else
      # Question not found in exact form in the document
      nil
    end
  end
  
  # Extract a potential answer from text following a question
  defp extract_potential_answer(text) do
    # Split by new line or another question (ending with "?")
    lines = String.split(text, ~r/\n|\?/, parts: 2)
    answer_line = Enum.at(lines, 0)
    
    if answer_line && String.trim(answer_line) != "" do
      # Remove any leading punctuation or whitespace
      String.trim(answer_line)
      |> String.replace(~r/^[\s\.\,\:\;]+/, "")
      |> String.trim()
    else
      nil
    end
  end
  
  # Format the final output in the expected structure
  defp format_output(questions_with_answers) do
    questions_and_answers =
      Enum.map(questions_with_answers, fn {question, answer} ->
        %{"question" => question, "answer" => answer || "No answer available."}
      end)
      
    {:ok, questions_and_answers}
  end
  
  # Simple caching mechanism
  defp get_cached_result(document_text) do
    # Use a hash of the document as the cache key
    cache_key = :crypto.hash(:md5, document_text) |> Base.encode16()
    
    # Check if the Agent is started
    case Process.whereis(__MODULE__) do
      nil -> 
        # Start the Agent if not running
        {:ok, _} = start_link()
        nil
      _ ->
        # Get the cached result if available
        Agent.get(__MODULE__, fn state -> Map.get(state, cache_key) end)
    end
  end
  
  defp cache_result(document_text, result) do
    # Use a hash of the document as the cache key
    cache_key = :crypto.hash(:md5, document_text) |> Base.encode16()
    
    # Check if the Agent is started
    case Process.whereis(__MODULE__) do
      nil -> 
        # Start the Agent if not running
        {:ok, _} = start_link()
      _ -> 
        :ok
    end
    
    # Cache the result
    Agent.update(__MODULE__, fn state -> Map.put(state, cache_key, result) end)
    
    result
  end
end