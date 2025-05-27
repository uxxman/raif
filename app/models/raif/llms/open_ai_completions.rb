# frozen_string_literal: true

class Raif::Llms::OpenAiCompletions < Raif::Llms::OpenAiBase
  include Raif::Concerns::Llms::OpenAiCompletions::MessageFormatting

  def perform_model_completion!(model_completion)
    model_completion.temperature ||= default_temperature
    parameters = build_request_parameters(model_completion)

    response = connection.post("chat/completions") do |req|
      req.body = parameters
    end

    response_json = response.body

    model_completion.update!(
      response_tool_calls: extract_response_tool_calls(response_json),
      raw_response: response_json.dig("choices", 0, "message", "content"),
      completion_tokens: response_json.dig("usage", "completion_tokens"),
      prompt_tokens: response_json.dig("usage", "prompt_tokens"),
      total_tokens: response_json.dig("usage", "total_tokens"),
      response_format_parameter: parameters.dig(:response_format, :type)
    )

    model_completion
  end

private

  def extract_response_tool_calls(resp)
    return if resp.dig("choices", 0, "message", "tool_calls").blank?

    resp.dig("choices", 0, "message", "tool_calls").map do |tool_call|
      {
        "name" => tool_call["function"]["name"],
        "arguments" => JSON.parse(tool_call["function"]["arguments"])
      }
    end
  end

  def build_request_parameters(model_completion)
    formatted_system_prompt = format_system_prompt(model_completion)

    messages = model_completion.messages
    messages_with_system = if formatted_system_prompt.blank?
      messages
    else
      [{ "role" => "system", "content" => formatted_system_prompt }] + messages
    end

    parameters = {
      model: api_name,
      messages: messages_with_system,
      temperature: model_completion.temperature.to_f
    }

    # If the LLM supports native tool use and there are available tools, add them to the parameters
    if supports_native_tool_use? && model_completion.available_model_tools.any?
      parameters[:tools] = model_completion.available_model_tools_map.map do |_tool_name, tool|
        validate_json_schema!(tool.tool_arguments_schema)

        {
          type: "function",
          function: {
            name: tool.tool_name,
            description: tool.tool_description,
            parameters: tool.tool_arguments_schema
          }
        }
      end
    end

    # Add response format if needed
    response_format = determine_response_format(model_completion)
    parameters[:response_format] = response_format if response_format

    parameters
  end

end
