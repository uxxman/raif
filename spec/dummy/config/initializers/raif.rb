# frozen_string_literal: true

Raif.configure do |config|
  # config.conversations_controller = "ConversationsController"
  # config.conversation_entries_controller = "ConversationEntriesController"

  config.bedrock_embedding_models_enabled = true
  config.bedrock_models_enabled = true

  config.authorize_controller_action = ->() { true }
  config.authorize_admin_controller_action = ->() { true }
end
