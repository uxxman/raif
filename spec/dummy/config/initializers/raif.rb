# frozen_string_literal: true

Raif.configure do |config|
  config.bedrock_embedding_models_enabled = true
  config.bedrock_models_enabled = true

  config.authorize_controller_action = ->() { true }
end
