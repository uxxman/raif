# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::Llms::OpenAiResponses, type: :model do
  let(:llm){ Raif.llm(:open_ai_responses_gpt_4o) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_connection) do
    Faraday.new do |builder|
      builder.adapter :test, stubs
      builder.request :json
      builder.response :json
      builder.response :raise_error
    end
  end

  before do
    allow(llm).to receive(:connection).and_return(test_connection)
  end

  describe "#chat" do
    context "when the response format is text" do
      let(:response_body) do
        {
          "id" => "resp_abc123",
          "object" => "response",
          "created_at" => 1748365161,
          "status" => "completed",
          "background" => false,
          "error" => nil,
          "incomplete_details" => nil,
          "instructions" => nil,
          "max_output_tokens" => nil,
          "model" => "gpt-4o",
          "output" => [
            {
              "id" => "msg_abc123",
              "type" => "message",
              "status" => "completed",
              "content" => [
                {
                  "type" => "output_text",
                  "annotations" => [],
                  "text" => "Response content"
                }
              ],
              "role" => "assistant"
            }
          ],
          "parallel_tool_calls" => true,
          "previous_response_id" => nil,
          "reasoning" => { "effort" => nil, "summary" => nil },
          "service_tier" => "default",
          "store" => true,
          "temperature" => 0.7,
          "text" => { "format" => { "type" => "text" } },
          "tool_choice" => "auto",
          "tools" => [],
          "top_p" => 1.0,
          "truncation" => "disabled",
          "usage" => {
            "input_tokens" => 5,
            "input_tokens_details" => { "cached_tokens" => 0 },
            "output_tokens" => 10,
            "output_tokens_details" => { "reasoning_tokens" => 0 },
            "total_tokens" => 15
          },
          "user" => nil,
          "metadata" => {}
        }
      end

      before do
        stubs.post("responses") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
      end

      it "makes a request to the OpenAI Responses API and processes the response" do
        model_completion = llm.chat(messages: [{ role: "user", content: "Hello" }], system_prompt: "You are a helpful assistant")

        expect(model_completion.raw_response).to eq("Response content")
        expect(model_completion.completion_tokens).to eq(10)
        expect(model_completion.prompt_tokens).to eq(5)
        expect(model_completion.total_tokens).to eq(15)
        expect(model_completion).to be_persisted
        expect(model_completion.messages).to eq([{ "role" => "user", "content" => [{ "text" => "Hello", "type" => "input_text" }] }])
        expect(model_completion.system_prompt).to eq("You are a helpful assistant")
        expect(model_completion.temperature).to eq(0.7)
        expect(model_completion.max_completion_tokens).to eq(nil)
        expect(model_completion.response_format).to eq("text")
        expect(model_completion.source).to be_nil
        expect(model_completion.llm_model_key).to eq("open_ai_responses_gpt_4o")
        expect(model_completion.model_api_name).to eq("gpt-4o")
        expect(model_completion.response_format_parameter).to be_nil
      end
    end

    context "when the response format is json" do
      let(:response_body) do
        {
          "id" => "resp_abc123",
          "object" => "response",
          "created_at" => 1748368556,
          "status" => "completed",
          "background" => false,
          "error" => nil,
          "incomplete_details" => nil,
          "instructions" => "You are a helpful assistant who specializes in telling jokes. Your response should be a properly formatted JSON object containing a single `joke` key. Do not include any other text in your response outside the JSON object. Return your response as json.", # rubocop:disable Layout/LineLength
          "max_output_tokens" => nil,
          "model" => "gpt-4.1-mini-2025-04-14",
          "output" => [{
            "id" => "msg_abc123",
            "type" => "message",
            "status" => "completed",
            "content" => [{
              "type" => "output_text",
              "annotations" => [],
              "text" => "{\n  \"joke\": \"Why don't scientists trust atoms? Because they make up everything!\"\n}"
            }],
            "role" => "assistant"
          }],
          "parallel_tool_calls" => true,
          "previous_response_id" => nil,
          "reasoning" => { "effort" => nil, "summary" => nil },
          "service_tier" => "default",
          "store" => true,
          "temperature" => 0.7,
          "text" => { "format" => { "type" => "json_object" } },
          "tool_choice" => "auto",
          "tools" => [],
          "top_p" => 1.0,
          "truncation" => "disabled",
          "usage" => {
            "input_tokens" => 90,
            "input_tokens_details" => { "cached_tokens" => 0 },
            "output_tokens" => 21,
            "output_tokens_details" => { "reasoning_tokens" => 0 },
            "total_tokens" => 111
          },
          "user" => nil,
          "metadata" => {}
        }
      end

      before do
        stubs.post("responses") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
      end

      it "makes a request to the OpenAI Responses API and processes the response" do
        messages = [
          { role: "user", content: "Hello" },
          { role: "assistant", content: "Hello! How can I assist you today?" },
          { role: "user", content: "Can you you tell me a joke? Respond in json." },
        ]

        system_prompt = "You are a helpful assistant who specializes in telling jokes. Your response should be a properly formatted JSON object containing a single `joke` key. Do not include any other text in your response outside the JSON object." # rubocop:disable Layout/LineLength

        model_completion = llm.chat(messages: messages, response_format: :json, system_prompt: system_prompt)

        expect(model_completion.raw_response).to eq("{\n  \"joke\": \"Why don't scientists trust atoms? Because they make up everything!\"\n}")
        expect(model_completion.parsed_response).to eq({ "joke" => "Why don't scientists trust atoms? Because they make up everything!" })
        expect(model_completion.completion_tokens).to eq(21)
        expect(model_completion.prompt_tokens).to eq(90)
        expect(model_completion.total_tokens).to eq(111)
        expect(model_completion).to be_persisted
        expect(model_completion.messages).to eq([
          { "role" => "user", "content" => [{ "text" => "Hello", "type" => "input_text" }] },
          { "role" => "assistant", "content" => [{ "text" => "Hello! How can I assist you today?", "type" => "output_text" }] },
          { "role" => "user", "content" => [{ "text" => "Can you you tell me a joke? Respond in json.", "type" => "input_text" }] }
        ])
        expect(model_completion.system_prompt).to eq(system_prompt)
        expect(model_completion.temperature).to eq(0.7)
        expect(model_completion.max_completion_tokens).to eq(nil)
        expect(model_completion.response_format).to eq("json")
        expect(model_completion.source).to be_nil
        expect(model_completion.llm_model_key).to eq("open_ai_responses_gpt_4o")
        expect(model_completion.model_api_name).to eq("gpt-4o")
        expect(model_completion.response_format_parameter).to eq("json_object")
      end
    end

    context "when the response includes function calls" do
      let(:response_body) do
        {
          "id" => "resp_abc123",
          "object" => "response",
          "created_at" => 1748370334,
          "status" => "completed",
          "background" => false,
          "error" => nil,
          "incomplete_details" => nil,
          "instructions" => nil,
          "max_output_tokens" => nil,
          "model" => "gpt-4.1-mini-2025-04-14",
          "output" => [{
            "id" => "fc_abc123",
            "type" => "function_call",
            "status" => "completed",
            "arguments" => "{\"query\":\"Ruby on Rails\"}",
            "call_id" => "call_WOCGRphTJCyulRuYMwFbRhIO",
            "name" => "wikipedia_search"
          }],
          "parallel_tool_calls" => true,
          "previous_response_id" => nil,
          "reasoning" => { "effort" => nil, "summary" => nil },
          "service_tier" => "default",
          "store" => true,
          "temperature" => 0.7,
          "text" => { "format" => { "type" => "text" } },
          "tool_choice" => "auto",
          "tools" => [{
            "type" => "function",
            "description" => "Search Wikipedia for information",
            "name" => "wikipedia_search",
            "parameters" => {
              "type" => "object",
              "additionalProperties" => false,
              "properties" => { "query" => { "type" => "string", "description" => "The query to search Wikipedia for" } },
              "required" => ["query"]
            },
            "strict" => true
          }],
          "top_p" => 1.0,
          "truncation" => "disabled",
          "usage" => {
            "input_tokens" => 54,
            "input_tokens_details" => { "cached_tokens" => 0 },
            "output_tokens" => 17,
            "output_tokens_details" => { "reasoning_tokens" => 0 },
            "total_tokens" => 71
          },
          "user" => nil,
          "metadata" => {}
        }
      end

      before do
        stubs.post("responses") do |_env|
          [200, { "Content-Type" => "application/json" }, response_body]
        end
      end

      it "extracts tool calls from the response" do
        model_completion = llm.chat(
          messages: [{ role: "user", content: "What Wikipedia pages are there about Ruby on Rails?" }],
          available_model_tools: [Raif::ModelTools::WikipediaSearch]
        )

        expect(model_completion.response_tool_calls).to eq([
          {
            "name" => "wikipedia_search",
            "arguments" => { "query" => "Ruby on Rails" }
          }
        ])
        expect(model_completion.raw_response).to eq(nil)
      end
    end

    context "when the API returns a 400-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "error": {
              "message": "API rate limit exceeded",
              "type": "rate_limit_error",
              "param": null,
              "code": null
            }
          }
        JSON
      end

      before do
        stubs.post("responses") do |_env|
          raise Faraday::ClientError.new(
            "Rate limited",
            { status: 429, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ClientError with the error message" do
        expect do
          llm.chat(messages: [{ role: "user", content: "Hello" }])
        end.to raise_error(Faraday::ClientError)
      end
    end

    context "when the API returns a 500-level error" do
      let(:error_response_body) do
        <<~JSON
          {
            "error": {
              "message": "Internal server error",
              "type": "server_error",
              "param": null,
              "code": null
            }
          }
        JSON
      end

      before do
        stubs.post("responses") do |_env|
          raise Faraday::ServerError.new(
            "Internal server error",
            { status: 500, body: error_response_body }
          )
        end

        allow(Raif.config).to receive(:llm_request_max_retries).and_return(0)
      end

      it "raises a Faraday::ServerError with the error message" do
        expect do
          llm.chat(messages: [{ role: "user", content: "Hello" }])
        end.to raise_error(Faraday::ServerError, "Internal server error")
      end
    end
  end

  describe "#build_request_parameters" do
    let(:parameters) { llm.send(:build_request_parameters, model_completion) }

    context "for text response format" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.8,
          response_format: "text",
          system_prompt: system_prompt
        )
      end

      context "with system prompt" do
        let(:system_prompt) { "You are a helpful assistant" }

        it "includes instructions (system prompt) in the parameters" do
          expect(parameters[:model]).to eq("gpt-4o")
          expect(parameters[:temperature]).to eq(0.8)
          expect(parameters[:input]).to eq([{ "role" => "user", "content" => "Hello" }])
          expect(parameters[:instructions]).to eq("You are a helpful assistant")
          expect(parameters[:response_format]).to be_nil
        end
      end

      context "without system prompt" do
        let(:system_prompt) { nil }

        it "builds parameters without instructions" do
          expect(parameters[:model]).to eq("gpt-4o")
          expect(parameters[:temperature]).to eq(0.8)
          expect(parameters[:input]).to eq([{ "role" => "user", "content" => "Hello" }])
          expect(parameters[:instructions]).to be_nil
        end
      end
    end

    context "for JSON response format" do
      let(:system_prompt) { "You are a helpful assistant" }
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          system_prompt: system_prompt,
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.5,
          response_format: "json"
        )
      end

      context "with existing system prompt" do
        it "appends 'Return your response as json.' to the system prompt" do
          expect(parameters[:instructions]).to eq("You are a helpful assistant. Return your response as JSON.")
        end
      end

      context "with no existing system prompt" do
        let(:system_prompt) { nil }

        it "Sets the instructions to 'Return your response as JSON.'" do
          expect(parameters[:instructions]).to eq("Return your response as JSON.")
        end
      end

      context "when the model completion has a json_response_schema" do
        before do
          model_completion.source = Raif::TestJsonTask.new
        end

        it "sets the response_format to json_schema" do
          expect(parameters[:text]).to eq({
            format: {
              type: "json_schema",
              json_schema: {
                name: "json_response_schema",
                strict: true,
                schema: {
                  type: "object",
                  additionalProperties: false,
                  required: ["joke", "answer"],
                  properties: {
                    joke: { type: "string" },
                    answer: { type: "string" }
                  }
                }
              }
            }
          })
        end
      end

      context "when the model completion does not have a json_response_schema" do
        it "sets the response_format to json_object" do
          expect(model_completion.json_response_schema).to be_nil
          expect(parameters[:text]).to eq({ format: { type: "json_object" } })
        end
      end
    end

    context "with max_completion_tokens" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.8,
          response_format: "text",
          max_completion_tokens: 1000
        )
      end

      it "includes max_output_tokens in the parameters" do
        expect(parameters[:max_output_tokens]).to eq(1000)
      end
    end

    context "with tools" do
      let(:model_completion) do
        mc = Raif::ModelCompletion.new(
          messages: [{ role: "user", content: "Hello" }],
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o",
          temperature: 0.8,
          response_format: "text"
        )
        allow(mc).to receive(:available_model_tools).and_return(["Raif::TestModelTool"])
        mc
      end

      before do
        allow(llm).to receive(:supports_native_tool_use?).and_return(true)
      end

      it "includes tools in the parameters" do
        expect(parameters[:tools]).to include({
          type: "function",
          name: "test_model_tool",
          description: "Mock Tool Description",
          parameters: {
            type: "object",
            additionalProperties: false,
            required: ["items"],
            properties: {
              items: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  required: ["title", "description"],
                  properties: {
                    title: {
                      type: "string",
                      description: "The title of the item"
                    },
                    description: {
                      type: "string"
                    }
                  }
                }
              }
            }
          }
        })
      end
    end
  end

  describe "#determine_response_format" do
    context "with text response format" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "text",
          llm_model_key: "open_ai_responses_gpt_4o"
        )
      end

      it "returns nil" do
        expect(llm.send(:determine_response_format, model_completion)).to be_nil
      end
    end

    context "with json response format but no json_response_schema" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o"
        )
      end

      it "returns the default json_object format" do
        expect(model_completion.json_response_schema).to eq(nil)
        expect(llm.send(:determine_response_format, model_completion)).to eq({ type: "json_object" })
      end
    end

    context "with json response format and a model that doesn't support structured outputs" do
      let(:model_completion) do
        Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_responses_gpt_3_5_turbo",
          model_api_name: "gpt-3.5-turbo"
        )
      end

      it "returns json_object type when structured outputs are not supported" do
        llm = Raif.llm(:open_ai_responses_gpt_3_5_turbo)
        result = llm.send(:determine_response_format, model_completion)
        expect(result).to eq({ type: "json_object" })
      end
    end

    context "with json format and source with json_response_schema" do
      let(:schema) do
        {
          type: "object",
          additionalProperties: false,
          required: ["result"],
          properties: {
            result: { type: "string" }
          }
        }
      end

      let(:source) do
        double("Source").tap do |s|
          allow(s).to receive(:respond_to?).with(:json_response_schema).and_return(true)
          allow(s).to receive(:json_response_schema).and_return(schema)
        end
      end

      let(:model_completion) do
        mc = Raif::ModelCompletion.new(
          response_format: "json",
          llm_model_key: "open_ai_responses_gpt_4o",
          model_api_name: "gpt-4o"
        )
        allow(mc).to receive(:source).and_return(source)
        mc
      end

      it "returns json_schema format with schema" do
        result = llm.send(:determine_response_format, model_completion)
        expect(result).to eq({
          type: "json_schema",
          json_schema: {
            name: "json_response_schema",
            strict: true,
            schema: schema
          }
        })
      end
    end
  end

  describe "#extract_response_tool_calls" do
    context "when response has no output" do
      let(:response) { { "output" => nil } }

      it "returns nil" do
        expect(llm.send(:extract_response_tool_calls, response)).to be_nil
      end
    end

    context "when response has empty output" do
      let(:response) { { "output" => [] } }

      it "returns nil" do
        expect(llm.send(:extract_response_tool_calls, response)).to be_nil
      end
    end

    context "when response has only message outputs" do
      let(:response) do
        {
          "output" => [
            {
              "type" => "message",
              "content" => [{ "type" => "output_text", "text" => "Hello" }]
            }
          ]
        }
      end

      it "returns nil" do
        expect(llm.send(:extract_response_tool_calls, response)).to be_nil
      end
    end
  end

  describe "#extract_raw_response" do
    context "when response has no output" do
      let(:response) { { "output" => nil } }

      it "returns nil" do
        expect(llm.send(:extract_raw_response, response)).to be_nil
      end
    end

    context "when response has empty output" do
      let(:response) { { "output" => [] } }

      it "returns nil" do
        expect(llm.send(:extract_raw_response, response)).to be_nil
      end
    end

    context "when response has only function calls" do
      let(:response) do
        {
          "output" => [
            {
              "type" => "function_call",
              "name" => "get_weather",
              "arguments" => { "location" => "San Francisco" }
            }
          ]
        }
      end

      it "returns nil" do
        expect(llm.send(:extract_raw_response, response)).to be_nil
      end
    end

    context "when response has message outputs" do
      let(:response) do
        {
          "output" => [
            {
              "type" => "message",
              "content" => [
                { "type" => "output_text", "text" => "Hello" },
                { "type" => "output_text", "text" => "World" }
              ]
            }
          ]
        }
      end

      it "extracts and joins text content" do
        result = llm.send(:extract_raw_response, response)
        expect(result).to eq("Hello\nWorld")
      end
    end

    context "when response has multiple message outputs" do
      let(:response) do
        {
          "output" => [
            {
              "type" => "message",
              "content" => [
                { "type" => "output_text", "text" => "First message" }
              ]
            },
            {
              "type" => "message",
              "content" => [
                { "type" => "output_text", "text" => "Second message" }
              ]
            }
          ]
        }
      end

      it "extracts and joins text from all messages" do
        result = llm.send(:extract_raw_response, response)
        expect(result).to eq("First message\nSecond message")
      end
    end

    context "when response has mixed content types" do
      let(:response) do
        {
          "output" => [
            {
              "type" => "message",
              "content" => [
                { "type" => "output_text", "text" => "Text content" },
                { "type" => "image", "url" => "http://example.com/image.jpg" }
              ]
            }
          ]
        }
      end

      it "only extracts text content" do
        result = llm.send(:extract_raw_response, response)
        expect(result).to eq("Text content")
      end
    end
  end
end
