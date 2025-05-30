# frozen_string_literal: true

class Raif::Utils::HtmlFragmentProcessor
  TRACKING_PARAMS = %w[
    utm_source
    utm_medium
    utm_campaign
    utm_term
    utm_content
    utm_id
  ]

  class << self
    def clean_html_fragment(html, allowed_tags: nil, allowed_attributes: nil)
      fragment = html.is_a?(Nokogiri::HTML::DocumentFragment) ? html : Nokogiri::HTML.fragment(html)

      fragment.traverse do |node|
        if node.text? && node.text.strip.empty?
          node.remove
        end
      end

      allowed_tags = allowed_tags.presence || Rails::HTML5::SafeListSanitizer.allowed_tags
      allowed_attributes = allowed_attributes.presence || Rails::HTML5::SafeListSanitizer.allowed_attributes

      ActionController::Base.helpers.sanitize(fragment.to_html, tags: allowed_tags, attributes: allowed_attributes).strip
    end

    def convert_markdown_links_to_html(html)
      # Convert markdown links [text](url) to HTML links <a href="url" target="_blank" rel="noopener">text</a>
      html.gsub(/\[([^\]]*)\]\(([^)]+)\)/) do |_match|
        text = ::Regexp.last_match(1)
        url = ::Regexp.last_match(2)
        clean_url = strip_tracking_parameters(url)
        %(<a href="#{clean_url}" target="_blank" rel="noopener">#{text}</a>)
      end
    end

    def process_links(html, add_target_blank: true, strip_tracking_parameters: true)
      fragment = html.is_a?(Nokogiri::HTML::DocumentFragment) ? html : Nokogiri::HTML.fragment(html)

      fragment.css("a").each do |link|
        if add_target_blank
          link["target"] = "_blank"
          link["rel"] = "noopener"
        end

        if strip_tracking_parameters
          link["href"] = strip_tracking_parameters(link["href"])
        end
      end

      fragment.to_html
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

        # Parse query parameters and filter out tracking ones
        params = URI.decode_www_form(uri.query)
        clean_params = params.reject { |param, _| TRACKING_PARAMS.include?(param.downcase) }

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
end
