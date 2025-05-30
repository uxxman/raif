# frozen_string_literal: true

module Raif
  class Configuration
    attr_accessor :agent_types,
      :bedrock_models_enabled,
      :authorize_controller_action,
      :bedrock_model_name_prefix,
      :aws_bedrock_region,
      :bedrock_embedding_models_enabled,
      :conversation_system_prompt_intro,
      :conversation_types,
      :current_user_method,
      :default_embedding_model_key,
      :default_llm_model_key,
      :llm_api_requests_enabled,
      :llm_request_max_retries,
      :llm_request_retriable_exceptions,
      :model_superclass,
      :task_system_prompt_intro,
      :user_tool_types

    def initialize
      # Set default config
      @agent_types = Set.new(["Raif::Agents::ReActAgent", "Raif::Agents::NativeToolCallingAgent"])
      @bedrock_models_enabled = false
      @authorize_controller_action = ->{ false }
      @aws_bedrock_region = "us-east-1"
      @bedrock_model_name_prefix = "us"
      @bedrock_embedding_models_enabled = false
      @task_system_prompt_intro = "You are a helpful assistant."
      @conversation_system_prompt_intro = "You are a helpful assistant who is collaborating with a teammate."
      @conversation_types = Set.new(["Raif::Conversation"])
      @current_user_method = :current_user
      @default_embedding_model_key = "bedrock_titan_embed_text_v2"
      @default_llm_model_key = "bedrock_nova_pro"
      @llm_api_requests_enabled = true
      @llm_request_max_retries = 2
      @llm_request_retriable_exceptions = [
        Faraday::ConnectionFailed,
        Faraday::TimeoutError,
        Faraday::ServerError,
      ]
      @model_superclass = "ApplicationRecord"
      @user_tool_types = []
    end

    def validate!
      if Raif.llm_registry.blank?
        puts <<~EOS

          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          No LLMs are enabled in Raif. Make sure you have an API key configured for at least one LLM provider. You can do this by setting an API key in your environment variables or in config/initializers/raif.rb.

          See the README for more information: https://github.com/CultivateLabs/raif#setup
          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        EOS

        return
      end

      unless Raif.available_llm_keys.include?(default_llm_model_key.to_sym)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_llm_model_key was set to #{default_llm_model_key}, but must be one of: #{Raif.available_llm_keys.join(", ")}"
      end

      if Raif.embedding_model_registry.present? && Raif.available_embedding_model_keys.exclude?(default_embedding_model_key.to_sym)
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.default_embedding_model_key was set to #{default_embedding_model_key}, but must be one of: #{Raif.available_embedding_model_keys.join(", ")}" # rubocop:disable Layout/LineLength
      end

      if authorize_controller_action.respond_to?(:call)
        authorize_controller_action.freeze
      else
        raise Raif::Errors::InvalidConfigError,
          "Raif.config.authorize_controller_action must respond to :call and return a boolean"
      end
    end

  end
end
