# frozen_string_literal: true

Raif.configure do |config|
  # The AWS Bedrock region to use. Defaults to "us-east-1"
  # config.aws_bedrock_region = "eu-central-1"

  # Prefix to apply to the model name in AWS Bedrock API calls
  # config.bedrock_model_name_prefix = "eu"

  # Whether Titan embedding models are enabled. Defaults to false
  # config.bedrock_embedding_models_enabled = false

  # The default LLM model to use. Defaults to "bedrock_nova_pro"
  # Available keys:
  #   bedrock_claude_3_5_sonnet
  #   bedrock_claude_3_7_sonnet
  #   bedrock_claude_3_5_haiku
  #   bedrock_claude_3_opus
  #   bedrock_nova_pro
  #
  # config.default_llm_model_key = "bedrock_nova_pro"

  # The default embedding model to use when calling Raif.generate_embedding!
  # Defaults to "bedrock_titan_embed_text_v2"
  # Available keys:
  #   bedrock_titan_embed_text_v2
  #
  # config.default_embedding_model_key = "bedrock_titan_embed_text_v2"

  # The system prompt intro for Raif::Task instances. Defaults to "You are a helpful assistant."
  # config.task_system_prompt_intro = "You are a helpful assistant."
  # Or you can use a lambda to return a dynamic system prompt intro:
  # config.task_system_prompt_intro = ->(task){ "You are a helpful assistant. Today's date is #{Date.today.strftime('%B %d, %Y')}." }

  # The system prompt intro for Raif::Conversation instances. Defaults to "You are a helpful assistant who is collaborating with a teammate."
  # config.conversation_system_prompt_intro = "You are a helpful assistant who is collaborating with a teammate."
  # Or you can use a lambda to return a dynamic system prompt intro:
  # config.conversation_system_prompt_intro = ->(conversation){ "You are a helpful assistant talking to #{conversation.creator.email}. Today's date is #{Date.today.strftime('%B %d, %Y')}." }

  # The conversation types that are available. Defaults to ["Raif::Conversation"]
  # If you want to use custom conversation types that inherits from Raif::Conversation, you can add them here.
  # config.conversation_types += ["Raif::MyConversation"]

  # The agent types that are available. Defaults to Set.new(["Raif::Agents::ReActAgent", "Raif::Agents::NativeToolCallingAgent"])
  # If you want to use custom agent types that inherits from Raif::Agent, you can add them here.
  # config.agent_types += ["MyAgent"]

  # The user tool types that are available. Defaults to []
  # config.user_tool_types = []
end
