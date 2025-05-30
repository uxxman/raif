# frozen_string_literal: true

module Raif
  class Engine < ::Rails::Engine
    isolate_namespace Raif

    config.after_initialize do
      require "aws-sdk-bedrockruntime"

      Raif.default_llms[Raif::Llms::Bedrock].each do |llm_config|
        Raif.register_llm(Raif::Llms::Bedrock, **llm_config)
      end
    end

    config.after_initialize do
      next unless Raif.config.bedrock_embedding_models_enabled

      Raif.default_embedding_models[Raif::EmbeddingModels::Bedrock].each do |embedding_model_config|
        Raif.register_embedding_model(Raif::EmbeddingModels::Bedrock, **embedding_model_config)
      end
    end

    config.after_initialize do
      Raif.config.validate!
    end
  end
end
