# frozen_string_literal: true

module Raif::Concerns::Llms::OpenAiResponses::ToolFormatting
  extend ActiveSupport::Concern

  def build_tools_array(model_completion)
    tools = model_completion.available_model_tools_map.map do |_tool_name, tool|
      if tool.provider_managed?
        format_provider_managed_tool(tool)
      else
        # It's a developer-managed tool
        validate_json_schema!(tool.tool_arguments_schema)

        {
          type: "function",
          name: tool.tool_name,
          description: tool.tool_description,
          parameters: tool.tool_arguments_schema
        }
      end
    end

    tools
  end

  def format_provider_managed_tool(tool)
    case tool.name
    when "Raif::ModelTools::ProviderManaged::WebSearch"
      { type: "web_search_preview" }
    else
      raise Raif::Errors::UnsupportedFeatureError,
        "Invalid provider-managed tool: #{tool.name}. Supported tools are: #{Raif::ModelTools::ProviderManaged::Base.subclasses.map(&:name).join(", ")}"
    end
  end
end
