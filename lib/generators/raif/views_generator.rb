# frozen_string_literal: true

module Raif
  class ViewsGenerator < Rails::Generators::Base
    source_root File.expand_path("../../../app/views/raif", __dir__)

    desc "Copies Raif conversation views to your application for customization"

    def copy_views
      directory "conversations", "app/views/raif/conversations"
      directory "conversation_entries", "app/views/raif/conversation_entries"
    end

    def success_message
      say_status :success, "Raif conversation views have been copied to your application", :green
      say "\nYou can now customize these views in:"
      say "  app/views/raif/conversations/"
      say "  app/views/raif/conversation_entries/"
      say "\nNote: These views will now override the default Raif engine views."
    end
  end
end
