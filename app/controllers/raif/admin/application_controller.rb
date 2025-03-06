# frozen_string_literal: true

module Raif
  module Admin
    class ApplicationController < Raif::ApplicationController
      include Pagy::Backend

      layout "raif/admin"

    private

      def authorize_raif_action
        unless instance_exec(&Raif.config.authorize_admin_controller_action)
          raise Raif::Errors::ActionNotAuthorizedError, "Admin action not authorized"
        end
      end

    end
  end
end
