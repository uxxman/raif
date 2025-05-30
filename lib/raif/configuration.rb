# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :agent_types,
      :bedrock_model_name_prefix,
      :aws_bedrock_region,
      :bedrock_embedding_models_enabled,
      :conversation_system_prompt_intro,
      :conversation_types,
      :default_embedding_model_key,
      :default_llm_model_key,
      :task_system_prompt_intro,
      :user_tool_types

    def initialize
      # Set default config
      @agent_types = Set.new(["Raif::Agents::ReActAgent", "Raif::Agents::NativeToolCallingAgent"])
      @aws_bedrock_region = "us-east-1"
      @bedrock_model_name_prefix = "us"
      @bedrock_embedding_models_enabled = false
      @task_system_prompt_intro = "You are a helpful assistant."
      @conversation_system_prompt_intro = "You are a helpful assistant who is collaborating with a teammate."
      @conversation_types = Set.new(["Raif::Conversation"])
      @default_embedding_model_key = "bedrock_titan_embed_text_v2"
      @default_llm_model_key = "bedrock_nova_pro"
      @user_tool_types = []
    end

    def validate!
      unless Raif.available_llm_keys.include?(default_llm_model_key.to_sym)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_llm_model_key was set to #{default_llm_model_key}, but must be one of: #{Raif.available_llm_keys.join(", ")}"
      end

      if Raif.embedding_model_registry.present? && Raif.available_embedding_model_keys.exclude?(default_embedding_model_key.to_sym)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_embedding_model_key was set to #{default_embedding_model_key}, but must be one of: #{Raif.available_embedding_model_keys.join(", ")}" # rubocop:disable Layout/LineLength
      end
    end

  end
end
