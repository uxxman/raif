# frozen_string_literal: true

module Raif
  module Generators
    class ConversationGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Creates a new conversation type in the app/models/raif/conversations directory"

      def create_conversation_file
        template "conversation.rb.tt", File.join("app/models/raif/conversations", "#{file_name}.rb")
      end

      def create_directory
        empty_directory "app/models/raif/conversations" unless File.directory?("app/models/raif/conversations")
      end

      def success_message
        say_status :success, "Conversation type created successfully", :green
        say "\nYou can now implement your conversation type in:"
        say "  app/models/raif/conversations/#{file_name}.rb\n\n"
        say "\nDon't forget to add it to the config.conversation_types in your Raif configuration"
        say "For example: config.conversation_types += ['Raif::Conversations::#{class_name}']\n\n"
      end
    end
  end
end
