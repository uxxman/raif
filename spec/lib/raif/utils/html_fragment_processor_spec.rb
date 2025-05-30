# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Utils::HtmlFragmentProcessor do
  describe ".clean_html_fragment" do
    context "when cleaning HTML content" do
      it "removes empty text nodes" do
        html = "<p>Hello</p>  <div>  </div><span>World</span>"
        result = described_class.clean_html_fragment(html)
        expect(result).not_to include("  ")
      end

      it "sanitizes dangerous HTML tags by default" do
        html = "<script>alert('xss')</script><p>Safe content</p>"
        result = described_class.clean_html_fragment(html)
        expect(result).not_to include("<script>")
        expect(result).to include("Safe content")
      end

      it "allows custom allowed_tags" do
        html = "<p>Paragraph</p><div>Div content</div><span>Span content</span>"
        result = described_class.clean_html_fragment(html, allowed_tags: %w[p span])
        expect(result).to include("<p>Paragraph</p>")
        expect(result).to include("<span>Span content</span>")
        expect(result).not_to include("<div>")
        expect(result).to include("Div content") # content should remain
      end

      it "allows custom allowed_attributes" do
        html = '<p class="test" id="para">Content</p>'
        result = described_class.clean_html_fragment(html, allowed_attributes: %w[class])
        expect(result).to include('class="test"')
        expect(result).not_to include('id="para"')
      end

      it "strips leading and trailing whitespace from result" do
        html = "  <p>Content</p>  "
        result = described_class.clean_html_fragment(html)
        expect(result).to eq("<p>Content</p>")
      end

      it "handles empty input" do
        result = described_class.clean_html_fragment("")
        expect(result).to eq("")
      end

      it "handles nil input gracefully" do
        expect { described_class.clean_html_fragment(nil) }.not_to raise_error
      end
    end
  end

  describe ".convert_markdown_links_to_html" do
    context "when converting markdown links" do
      it "converts simple markdown links to HTML" do
        markdown = "Check out [Google](https://google.com) for search."
        result = described_class.convert_markdown_links_to_html(markdown)
        expected = 'Check out <a href="https://google.com" target="_blank" rel="noopener">Google</a> for search.'
        expect(result).to eq(expected)
      end

      it "converts multiple markdown links" do
        markdown = "Visit [Google](https://google.com) and [GitHub](https://github.com)"
        result = described_class.convert_markdown_links_to_html(markdown)
        expect(result).to include('<a href="https://google.com" target="_blank" rel="noopener">Google</a>')
        expect(result).to include('<a href="https://github.com" target="_blank" rel="noopener">GitHub</a>')
      end

      it "handles links with tracking parameters by stripping them" do
        markdown = "[Example](https://example.com?utm_source=test&regular_param=keep)"
        result = described_class.convert_markdown_links_to_html(markdown)
        expect(result).to include('href="https://example.com?regular_param=keep"')
        expect(result).not_to include("utm_source")
      end

      it "handles empty link text" do
        markdown = "[](https://example.com)"
        result = described_class.convert_markdown_links_to_html(markdown)
        expect(result).to include('<a href="https://example.com" target="_blank" rel="noopener"></a>')
      end

      it "handles links with special characters in text" do
        markdown = "[Test & Example](https://example.com)"
        result = described_class.convert_markdown_links_to_html(markdown)
        expect(result).to include(">Test & Example</a>")
      end

      it "leaves non-markdown links unchanged" do
        text = "Visit https://example.com directly"
        result = described_class.convert_markdown_links_to_html(text)
        expect(result).to eq(text)
      end

      it "handles malformed markdown links" do
        text = "[Incomplete link without closing paren](https://example.com"
        result = described_class.convert_markdown_links_to_html(text)
        expect(result).to eq(text) # Should remain unchanged
      end
    end
  end

  describe ".strip_tracking_parameters" do
    context "when stripping tracking parameters" do
      it "removes UTM parameters" do
        url = "https://example.com?utm_source=google&utm_medium=cpc&regular_param=keep"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com?regular_param=keep")
      end

      it "removes all UTM parameters" do
        url = "https://example.com?utm_source=test&utm_medium=test&utm_campaign=test&utm_term=test&utm_content=test&utm_id=test"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com")
      end

      it "handles case-insensitive UTM parameters" do
        url = "https://example.com?UTM_SOURCE=test&Utm_Medium=test&regular=keep"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com?regular=keep")
      end

      it "preserves non-tracking parameters" do
        url = "https://example.com?page=1&limit=10&utm_source=test"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com?page=1&limit=10")
      end

      it "handles URLs without query parameters" do
        url = "https://example.com/path"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq(url)
      end

      it "handles URLs without question mark" do
        url = "https://example.com"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq(url)
      end

      it "handles relative URLs" do
        url = "/path?utm_source=test&param=keep"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("/path?param=keep")
      end

      it "handles anchor URLs" do
        url = "#section?utm_source=test"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("#section?utm_source=test") # Fragment URLs don't have actual query parameters
      end

      it "handles invalid URLs gracefully" do
        invalid_url = "not-a-valid-url with spaces"
        result = described_class.strip_tracking_parameters(invalid_url)
        expect(result).to eq(invalid_url)
      end

      it "handles URLs with only tracking parameters" do
        url = "https://example.com?utm_source=test&utm_medium=test"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com")
      end

      it "preserves URL fragments" do
        url = "https://example.com?utm_source=test&param=keep#fragment"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq("https://example.com?param=keep#fragment")
      end

      it "handles URLs without scheme but with tracking params" do
        url = "example.com?utm_source=test&param=keep"
        result = described_class.strip_tracking_parameters(url)
        expect(result).to eq(url) # Should return unchanged for URLs without valid scheme
      end
    end
  end

  describe "TRACKING_PARAMS constant" do
    it "includes all expected UTM parameters" do
      expected_params = %w[
        utm_source
        utm_medium
        utm_campaign
        utm_term
        utm_content
        utm_id
      ]
      expect(described_class::TRACKING_PARAMS).to eq(expected_params)
    end
  end
end
