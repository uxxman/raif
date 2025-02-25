# frozen_string_literal: true

require "raif/version"
require "raif/root"
require "raif/languages"
require "raif/engine"
require "raif/configuration"
require "raif/errors"
require "raif/llm_client"
require "raif/model_tool"

require "openai"

module Raif
  class << self
    attr_accessor :configuration

    attr_writer :logger
  end

  def self.config
    @configuration ||= Raif::Configuration.new
  end

  def self.configure
    yield(config)
  end

  def self.logger
    @logger ||= Rails.logger
  end

  def self.available_models
    LlmClient.available_models
  end
end
