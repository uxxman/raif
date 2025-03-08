# frozen_string_literal: true

module Raif::Completions
  class ConversationEntry < Raif::Completion
    belongs_to :raif_conversation_entry, class_name: "Raif::ConversationEntry"

    llm_response_format :json
    llm_completion_args :raif_conversation_entry

    delegate :raif_conversation, to: :raif_conversation_entry

    def build_system_prompt
      <<~PROMPT
        #{super}

        #{raif_conversation.system_prompt_addition}
      PROMPT
    end

    def build_prompt
      raif_conversation_entry.full_user_message
    end

    def messages
      @messages ||= raif_conversation.llm_messages
    end

  end
end
