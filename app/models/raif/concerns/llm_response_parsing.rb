# frozen_string_literal: true

module Raif::Concerns::LlmResponseParsing
  extend ActiveSupport::Concern

  included do
    normalizes :raw_response, with: ->(text){ text&.strip }

    enum :response_format, Raif::Llm.valid_response_formats, prefix: true

    validates :response_format, presence: true, inclusion: { in: response_formats.keys }

    class_attribute :allowed_tags
    class_attribute :allowed_attributes
  end

  class_methods do
    def llm_response_format(format)
      raise ArgumentError, "response_format must be one of: #{response_formats.keys.join(", ")}" unless response_formats.keys.include?(format.to_s)

      after_initialize -> { self.response_format = format }, if: :new_record?
    end

    def llm_response_allowed_tags(tags)
      self.allowed_tags = tags
    end

    def llm_response_allowed_attributes(attributes)
      self.allowed_attributes = attributes
    end
  end

  # Parses the response from the LLM into a structured format, based on the response_format.
  # If the response format is JSON, it will be parsed using JSON.parse.
  # If the response format is HTML, it will be sanitized via ActionController::Base.helpers.sanitize.
  #
  # @return [Object] The parsed response.
  def parsed_response
    return if raw_response.blank?

    @parsed_response ||= if response_format_json?
      json = raw_response.gsub("```json", "").gsub("```", "")
      JSON.parse(json)
    elsif response_format_html?
      html = raw_response.strip.gsub("```html", "").chomp("```")
      html_with_converted_links = convert_markdown_links_to_html(html)
      clean_html_fragment(html_with_converted_links)
    else
      raw_response.strip
    end
  end

  def clean_html_fragment(html)
    fragment = Nokogiri::HTML.fragment(html)

    fragment.traverse do |node|
      if node.text? && node.text.strip.empty?
        node.remove
      end
    end

    allowed_tags = self.class.allowed_tags || Rails::HTML5::SafeListSanitizer.allowed_tags
    allowed_attributes = self.class.allowed_attributes || Rails::HTML5::SafeListSanitizer.allowed_attributes

    ActionController::Base.helpers.sanitize(fragment.to_html, tags: allowed_tags, attributes: allowed_attributes).strip
  end

private

  def convert_markdown_links_to_html(html)
    # Convert markdown links [text](url) to HTML links <a href="url" target="_blank" rel="noopener">text</a>
    html.gsub(/\[([^\]]*)\]\(([^)]+)\)/) do |_match|
      text = ::Regexp.last_match(1)
      url = ::Regexp.last_match(2)
      clean_url = strip_tracking_parameters(url)
      %(<a href="#{clean_url}" target="_blank" rel="noopener">#{text}</a>)
    end
  end

  def strip_tracking_parameters(url)
    return url unless url.include?("?")

    begin
      uri = URI.parse(url)
      return url unless uri.query

      # Only process URLs that have a valid scheme and host, or are relative URLs
      unless uri.scheme || url.start_with?("/", "#")
        return url
      end

      # List of tracking parameters to remove
      tracking_params = %w[
        utm_source
        utm_medium
        utm_campaign
        utm_term
        utm_content
        utm_id
      ]

      # Parse query parameters and filter out tracking ones
      params = URI.decode_www_form(uri.query)
      clean_params = params.reject { |param, _| tracking_params.include?(param.downcase) }

      # Rebuild the URL
      uri.query = if clean_params.empty?
        nil
      else
        URI.encode_www_form(clean_params)
      end

      uri.to_s
    rescue URI::InvalidURIError
      # If URL parsing fails, return the original URL
      url
    end
  end
end
