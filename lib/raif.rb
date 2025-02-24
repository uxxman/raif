# frozen_string_literal: true

require "raif/version"
require "raif/engine"
require "raif/configuration"

require "raif/llm_client"
require "raif/model_tool"

require "openai"

module Raif
  class << self
    attr_accessor :configuration
  end

  def self.config
    @configuration ||= Raif::Configuration.new
  end

  def self.configure
    yield(config)
  end
end
