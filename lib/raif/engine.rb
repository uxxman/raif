# frozen_string_literal: true

begin
  require "factory_bot_rails"
rescue LoadError # rubocop:disable Lint/SuppressedException
end

module Raif
  class Engine < ::Rails::Engine
    isolate_namespace Raif

    # If the host app is using FactoryBot, add the factories to the host app so they can be used in host apptests
    if defined?(FactoryBotRails)
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories/shared", __FILE__)]
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    config.after_initialize do
      next unless Raif.config.bedrock_models_enabled

      require "aws-sdk-bedrockruntime"

      Raif.default_llms[Raif::Llms::Bedrock].each do |llm_config|
        Raif.register_llm(Raif::Llms::Bedrock, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.bedrock_embedding_models_enabled

      require "aws-sdk-bedrockruntime"

      Raif.default_embedding_models[Raif::EmbeddingModels::Bedrock].each do |embedding_model_config|
        Raif.register_embedding_model(Raif::EmbeddingModels::Bedrock, **embedding_model_config)
      end
    end

    config.after_initialize do
      next unless Rails.env.test?

      Raif.config.conversation_types += ["Raif::TestConversation"]

      require "#{Raif::Engine.root}/spec/support/test_llm"
      Raif.register_llm(Raif::Llms::TestLlm, key: :raif_test_llm, api_name: "raif-test-llm")

      require "#{Raif::Engine.root}/spec/support/test_embedding_model"
      Raif.register_embedding_model(
        Raif::EmbeddingModels::Test,
        key: :raif_test_embedding_model,
        api_name: "raif-test-embedding-model",
        default_output_vector_size: 1536
      )
    end

    config.after_initialize do
      Raif.config.validate!
    end
  end
end
