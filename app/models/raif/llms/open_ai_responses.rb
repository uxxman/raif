# frozen_string_literal: true

class Raif::Llms::OpenAiResponses < Raif::Llms::OpenAiBase
  include Raif::Concerns::Llms::OpenAiResponses::MessageFormatting
  include Raif::Concerns::Llms::OpenAiResponses::ToolFormatting

  def perform_model_completion!(model_completion)
    model_completion.temperature ||= default_temperature
    parameters = build_request_parameters(model_completion)

    response = connection.post("responses") do |req|
      req.body = parameters
    end

    response_json = response.body

    model_completion.update!(
      response_tool_calls: extract_response_tool_calls(response_json),
      raw_response: extract_raw_response(response_json),
      response_array: response_json["output"],
      completion_tokens: response_json.dig("usage", "output_tokens"),
      prompt_tokens: response_json.dig("usage", "input_tokens"),
      total_tokens: response_json.dig("usage", "total_tokens"),
      response_format_parameter: parameters.dig(:text, :format, :type)
    )

    model_completion
  end

private

  def extract_response_tool_calls(resp)
    return if resp["output"].blank?

    tool_calls = []
    resp["output"].each do |output_item|
      next unless output_item["type"] == "function_call"

      tool_calls << {
        "name" => output_item["name"],
        "arguments" => JSON.parse(output_item["arguments"])
      }
    end

    tool_calls.any? ? tool_calls : nil
  end

  def extract_raw_response(resp)
    text_outputs = []

    output_messages = resp["output"]&.select{ |output_item| output_item["type"] == "message" }
    output_messages&.each do |output_message|
      output_message["content"].each do |content_item|
        text_outputs << content_item["text"] if content_item["type"] == "output_text"
      end
    end

    text_outputs.join("\n").presence
  end

  def build_request_parameters(model_completion)
    parameters = {
      model: api_name,
      input: model_completion.messages,
      temperature: model_completion.temperature.to_f
    }

    # Add instructions (system prompt) if present
    formatted_system_prompt = format_system_prompt(model_completion)
    if formatted_system_prompt.present?
      parameters[:instructions] = formatted_system_prompt
    end

    # Add max_output_tokens if specified
    if model_completion.max_completion_tokens.present?
      parameters[:max_output_tokens] = model_completion.max_completion_tokens
    end

    # If the LLM supports native tool use and there are available tools, add them to the parameters
    if supports_native_tool_use? && model_completion.available_model_tools.any?
      parameters[:tools] = build_tools_array(model_completion)
    end

    # Add response format if needed. Default will be { "type": "text" }
    response_format = determine_response_format(model_completion)
    if response_format.present?
      parameters[:text] = { format: response_format }
    end

    parameters
  end

end
