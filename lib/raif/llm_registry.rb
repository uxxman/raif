# frozen_string_literal: true

module Raif
  def self.llm_registry
    @llm_registry ||= {}
  end

  def self.register_llm(llm_class, llm_config)
    llm = llm_class.new(**llm_config)

    unless llm.valid?
      raise ArgumentError, "The LLM you tried to register is invalid: #{llm.errors.full_messages.join(", ")}"
    end

    @llm_registry ||= {}
    @llm_registry[llm.key] = llm_config.merge(llm_class: llm_class)
  end

  def self.llm(model_key)
    llm_config = llm_registry[model_key]

    if llm_config.nil?
      raise ArgumentError, "No LLM found for model key: #{model_key}. Available models: #{available_llm_keys.join(", ")}"
    end

    llm_class = llm_config[:llm_class]
    llm_class.new(**llm_config.except(:llm_class))
  end

  def self.available_llms
    llm_registry.values
  end

  def self.available_llm_keys
    llm_registry.keys
  end

  def self.llm_config(model_key)
    llm_registry[model_key]
  end

  def self.default_llms
    {
      Raif::Llms::Bedrock => [
        {
          key: :bedrock_claude_4_sonnet,
          api_name: "anthropic.claude-sonnet-4-20250514-v1:0",
          input_token_cost: 0.003 / 1000,
          output_token_cost: 0.015 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_4_opus,
          api_name: "anthropic.claude-opus-4-20250514-v1:0",
          input_token_cost: 0.015 / 1000,
          output_token_cost: 0.075 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_5_sonnet,
          api_name: "anthropic.claude-3-5-sonnet-20241022-v2:0",
          input_token_cost: 0.003 / 1000,
          output_token_cost: 0.015 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_7_sonnet,
          api_name: "anthropic.claude-3-7-sonnet-20250219-v1:0",
          input_token_cost: 0.003 / 1000,
          output_token_cost: 0.015 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_5_haiku,
          api_name: "anthropic.claude-3-5-haiku-20241022-v1:0",
          input_token_cost: 0.0008 / 1000,
          output_token_cost: 0.004 / 1000,
          max_completion_tokens: 8192
        },
        {
          key: :bedrock_claude_3_opus,
          api_name: "anthropic.claude-3-opus-20240229-v1:0",
          input_token_cost: 0.015 / 1000,
          output_token_cost: 0.075 / 1000,
          max_completion_tokens: 4096
        },
        {
          key: :bedrock_nova_pro,
          api_name: "amazon.nova-pro-v1:0",
          input_token_cost: 0.00105 / 1000,
          output_token_cost: 0.0042 / 1000,
          max_completion_tokens: 4096
        }
      ]
    }
  end
end
