# frozen_string_literal: true

module Raif
  class ApplicationController < ::ApplicationController
    before_action :authorize_raif_action

    def raif_current_user
      send(Raif.config.current_user_method) if respond_to?(Raif.config.current_user_method)
    end

  private

    def authorize_raif_action
      unless instance_exec(&Raif.config.authorize_controller_action)
        raise Raif::Errors::ActionNotAuthorizedError, "#{self.class.name}##{action_name} not authorized"
      end
    end
  end
end
