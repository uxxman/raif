# frozen_string_literal: true

module Raif
  module Shared
    module ConversationsHelper

      def raif_conversation(conversation)
        render "raif/conversations/full_conversation", conversation: conversation
      end

    end
  end
end
