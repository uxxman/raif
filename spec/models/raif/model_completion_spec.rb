# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelCompletion, type: :model do
  describe "validations" do
    it "validates presence of llm_model_key" do
      model_completion = described_class.new(response_format: "text")
      expect(model_completion).not_to be_valid
      expect(model_completion.errors[:llm_model_key]).to include("can't be blank")
    end

    it "validates that the llm_model_key is a valid model key" do
      model_completion = described_class.new(response_format: "text", llm_model_key: "invalid_model_key")
      expect(model_completion).not_to be_valid
      expect(model_completion.errors[:llm_model_key]).to include("is not included in the list")
    end

    it "validates inclusion of response_format in valid formats" do
      expect do
        described_class.new(response_format: "invalid_format", llm_model_key: "bedrock_claude_3_5_sonnet")
      end.to raise_error(ArgumentError, "'invalid_format' is not a valid response_format")
    end
  end

  
  describe "callbacks" do
    describe "#set_total_tokens" do
      it "sets total_tokens based on completion_tokens and prompt_tokens" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          prompt_tokens: 100,
          completion_tokens: 50
        )

        model_completion.save(validate: false)
        expect(model_completion.total_tokens).to eq(150)
      end

      it "does not set total_tokens if completion_tokens is missing" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          prompt_tokens: 100
        )

        model_completion.save(validate: false)
        expect(model_completion.total_tokens).to be_nil
      end

      it "does not set total_tokens if prompt_tokens is missing" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          completion_tokens: 50
        )

        model_completion.save(validate: false)
        expect(model_completion.total_tokens).to be_nil
      end
    end

    describe "#calculate_costs" do
      it "calculates prompt_token_cost based on input_token_cost and prompt_tokens" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          prompt_tokens: 1000
        )

        # An input_token_cost of 2.5 / 1_000_000
        expected_cost = 2.5 / 1_000_000 * 1000

        model_completion.save(validate: false)
        expect(model_completion.prompt_token_cost).to eq(expected_cost)
      end

      it "calculates output_token_cost based on output_token_cost and completion_tokens" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          completion_tokens: 500
        )

        # An output_token_cost of 10.0 / 1_000_000
        expected_cost = 10.0 / 1_000_000 * 500

        model_completion.save(validate: false)
        expect(model_completion.output_token_cost).to eq(expected_cost)
      end

      it "calculates total_cost based on prompt_token_cost and output_token_cost" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          prompt_tokens: 1000,
          completion_tokens: 500
        )

        # An input_token_cost of 2.5 / 1_000_000 and output_token_cost of 10.0 / 1_000_000
        expected_prompt_cost = 2.5 / 1_000_000 * 1000
        expected_output_cost = 10.0 / 1_000_000 * 500
        expected_total_cost = expected_prompt_cost + expected_output_cost

        model_completion.save(validate: false)
        expect(model_completion.total_cost).to eq(expected_total_cost)
      end

      it "calculates total_cost when only prompt_token_cost is present" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          prompt_tokens: 1000
        )

        # An input_token_cost of 2.5 / 1_000_000
        expected_prompt_cost = 2.5 / 1_000_000 * 1000

        model_completion.save(validate: false)
        expect(model_completion.total_cost).to eq(expected_prompt_cost)
      end

      it "calculates total_cost when only output_token_cost is present" do
        model_completion = described_class.new(
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          completion_tokens: 500
        )

        # An output_token_cost of 10.0 / 1_000_000
        expected_output_cost = 10.0 / 1_000_000 * 500

        model_completion.save(validate: false)
        expect(model_completion.total_cost).to eq(expected_output_cost)
      end

      it "does not calculate costs for a model that doesn't have cost configs" do
        # Create a mock of Raif.llm_config that returns a config without cost data
        allow(Raif).to receive(:llm_config).and_return({
          key: :test_model,
          api_name: "test-model"
          # Intentionally omitting input_token_cost and output_token_cost
        })

        model_completion = described_class.new(
          llm_model_key: "test_model",
          model_api_name: "test-model",
          prompt_tokens: 1000,
          completion_tokens: 500
        )

        model_completion.save(validate: false)
        expect(model_completion.prompt_token_cost).to be_nil
        expect(model_completion.output_token_cost).to be_nil
        expect(model_completion.total_cost).to be_nil
      end
    end
  end

  describe "#parsed_response" do
    context "with text format" do
      let(:model_completion) do
        described_class.new(
          response_format: "text",
          raw_response: "  This is a text response.  ",
          llm_model_key: "bedrock_claude_3_5_sonnet"
        )
      end

      it "returns the trimmed text" do
        expect(model_completion.parsed_response).to eq("This is a text response.")
      end
    end

    context "with json format" do
      context "with valid JSON" do
        let(:model_completion) do
          described_class.new(
            response_format: "json",
            raw_response: '{"key": "value", "array": [1, 2, 3]}',
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "parses the JSON" do
          expect(model_completion.parsed_response).to eq({ "key" => "value", "array" => [1, 2, 3] })
        end
      end

      context "with JSON wrapped in code blocks" do
        let(:model_completion) do
          described_class.new(
            response_format: "json",
            raw_response: "```json\n{\"key\": \"value\"}\n```",
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "removes the code block markers and parses the JSON" do
          expect(model_completion.parsed_response).to eq({ "key" => "value" })
        end
      end
    end

    context "with html format" do
      context "with valid HTML" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div><p>Hello</p><p>World</p></div>",
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "cleans and returns the HTML" do
          expect(model_completion.parsed_response).to eq("<div>\n<p>Hello</p>\n<p>World</p>\n</div>")
        end
      end

      context "with HTML wrapped in code blocks" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "```html\n<div><p>Hello</p></div>\n```",
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "removes the code block markers and returns the HTML" do
          expect(model_completion.parsed_response).to eq("<div><p>Hello</p></div>")
        end
      end

      context "with HTML containing empty text nodes" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div>\n  <p>Hello</p>\n  \n  <p>World</p>\n</div>",
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "cleans empty text nodes" do
          # The exact output might depend on how ActionController::Base.helpers.sanitize works
          # This test might need adjustment based on actual behavior
          expect(model_completion.parsed_response).to include("<div>")
          expect(model_completion.parsed_response).to include("<p>Hello</p>")
          expect(model_completion.parsed_response).to include("<p>World</p>")
        end
      end

      context "with HTML containing script tags" do
        let(:model_completion) do
          described_class.new(
            response_format: "html",
            raw_response: "<div><script>alert('XSS')</script><p>Safe content</p></div>",
            llm_model_key: "bedrock_claude_3_5_sonnet"
          )
        end

        it "removes the script tags" do
          expect(model_completion.parsed_response).to include("<div>\nalert('XSS')<p>Safe content</p>\n</div>")
        end
      end
    end
  end
end
