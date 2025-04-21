# frozen_string_literal: true

module Raif
  module Generators
    class AgentGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      desc "Creates a new Raif::Agent subclass in app/models/raif/agents"

      def create_application_agent
        template "application_agent.rb.tt", "app/models/raif/application_agent.rb" unless File.exist?("app/models/raif/application_agent.rb")
      end

      def create_agent
        template "agent.rb.tt", "app/models/raif/agents/#{file_name}.rb"
      end

      def create_directory
        empty_directory "app/models/raif/agents" unless File.directory?("app/models/raif/agents")
      end

    private

      def class_name
        name.classify
      end

      def file_name
        name.underscore
      end
    end
  end
end
