# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ModelCompletions", type: :feature do
  let(:user) { FB.create(:raif_test_user) }
  let(:task) { FB.create(:raif_test_task, creator: user) }
  let(:task2) { FB.create(:raif_test_task, creator: user) }
  let(:task3) { FB.create(:raif_test_task, creator: user) }
  let(:conversation) { FB.create(:raif_test_conversation, creator: user) }
  let(:conversation_entry) { FB.create(:raif_conversation_entry, raif_conversation: conversation, creator: user) }
  let(:agent) { FB.create(:raif_re_act_agent, creator: user) }

  describe "admin root redirect" do
    it "redirects from admin root to model completions index" do
      visit raif.admin_root_path
      expect(page).to have_current_path(raif.admin_model_completions_path)
    end
  end

  describe "index page" do
    let!(:model_completions) do
      [
        Raif::ModelCompletion.create!(
          source: agent,
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          response_format: "text",
          raw_response: "Test response 1",
          total_tokens: 1000
        ),
        Raif::ModelCompletion.create!(
          source: conversation_entry,
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          response_format: "text",
          raw_response: "Test response 2",
          total_tokens: 200
        )
      ]
    end

    let!(:json_completion) do
      Raif::ModelCompletion.create!(
        source: task,
        llm_model_key: "bedrock_claude_3_5_sonnet",
        model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
        response_format: "json",
        raw_response: '{"key": "value"}',
        prompt_tokens: 50,
        completion_tokens: 150,
        total_tokens: 200
      )
    end

    let!(:html_completion) do
      Raif::ModelCompletion.create!(
        source: task2,
        llm_model_key: "bedrock_claude_3_5_sonnet",
        model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
        response_format: "html",
        raw_response: "<div>Test HTML</div>",
        prompt_tokens: 75,
        completion_tokens: 125,
        total_tokens: 200
      )
    end

    let!(:long_completion) do
      Raif::ModelCompletion.create!(
        source: task3,
        llm_model_key: "bedrock_claude_3_5_sonnet",
        model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
        response_format: "text",
        raw_response: "a" * 200,
        total_tokens: 300
      )
    end

    it "displays model completions with all details and handles edge cases" do
      visit raif.admin_model_completions_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("raif.admin.common.model_completions"))
      expect(page).to have_content(I18n.t("raif.admin.common.id"))
      expect(page).to have_content(I18n.t("raif.admin.common.created_at"))
      expect(page).to have_content(I18n.t("raif.admin.common.source"))
      expect(page).to have_content(I18n.t("raif.admin.common.model"))
      expect(page).to have_content(I18n.t("raif.admin.common.response_format"))
      expect(page).to have_content(I18n.t("raif.admin.common.total_tokens"))
      expect(page).to have_content(I18n.t("raif.admin.common.response"))

      # Check model completions count and formats
      expect(page).to have_css("tr.raif-model-completion", count: 5) # Total number of model completions
      expect(page).to have_content("text")
      expect(page).to have_content("json")
      expect(page).to have_content("html")

      # Check model names
      expect(page).to have_content("bedrock_claude_3_5_sonnet")

      # Check token counts
      expect(page).to have_content("1,000")
      expect(page).to have_content("200")
      expect(page).to have_content("300")

      # Truncated long response
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::ModelCompletion.delete_all
      visit raif.admin_model_completions_path
      expect(page).to have_content(I18n.t("raif.admin.common.no_model_completions"))
    end
  end

  describe "show page" do
    let!(:text_completion) do
      Raif::ModelCompletion.create!(
        source: task,
        llm_model_key: "bedrock_claude_3_5_sonnet",
        model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
        response_format: "text",
        raw_response: "This is a test response",
        prompt_tokens: 2500,
        completion_tokens: 7500,
        total_tokens: 10000,
        messages: [
          { "role" => "user", "content" => "Test message" },
          { "role" => "assistant", "content" => "This is a test response" }
        ]
      )
    end

    it "displays the model response details and has a back link to the index" do
      visit raif.admin_model_completion_path(text_completion)

      expect(page).to have_content(I18n.t("raif.admin.model_completions.show.title", id: text_completion.id))

      # Check basic details
      expect(page).to have_content(text_completion.id.to_s)
      expect(page).to have_content(text_completion.source_type)
      expect(page).to have_content(text_completion.source_id.to_s)

      # Check timestamps
      expect(page).to have_content(text_completion.created_at.rfc822)

      # Check token counts
      expect(page).to have_content("2,500 (est. cost: $0.000375)") # prompt_tokens
      expect(page).to have_content("7,500 (est. cost: $0.004500)") # completion_tokens
      expect(page).to have_content("10,000 (est. cost: $0.004875)") # total_tokens

      # Check messages section
      expect(page).to have_content(I18n.t("raif.admin.common.messages"))
      expect(page).to have_content("User:")
      expect(page).to have_content("Test message")
      expect(page).to have_content("Assistant:")
      expect(page).to have_content("This is a test response")

      # Check response content
      expect(page).to have_content("This is a test response")

      # Check back link functionality
      expect(page).to have_link(I18n.t("raif.admin.model_completions.show.back_to_model_completions"), href: raif.admin_model_completions_path)

      click_link I18n.t("raif.admin.model_completions.show.back_to_model_completions")
      expect(page).to have_current_path(raif.admin_model_completions_path)
    end

    context "with JSON response format" do
      let!(:json_completion) do
        Raif::ModelCompletion.create!(
          source: task,
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          response_format: "json",
          raw_response: '{"key": "value", "nested": {"data": "test"}}',
          total_tokens: 150
        )
      end

      it "displays both raw and prettified JSON" do
        visit raif.admin_model_completion_path(json_completion)

        expect(page).to have_content(I18n.t("raif.admin.common.raw"))
        expect(page).to have_content('{"key": "value", "nested": {"data": "test"}}')

        expect(page).to have_content(I18n.t("raif.admin.common.prettified"))
        # The prettified JSON will have line breaks and indentation
        expect(page).to have_content('"key": "value"')
        expect(page).to have_content('"nested": {')
        expect(page).to have_content('"data": "test"')
      end
    end

    context "with HTML response format" do
      let!(:html_completion) do
        Raif::ModelCompletion.create!(
          source: task2,
          llm_model_key: "bedrock_claude_3_5_sonnet",
          model_api_name: "anthropic.claude-3-5-sonnet-20240620-v1:0",
          response_format: "html",
          raw_response: "<div><h1>Test</h1><p>HTML content</p></div>",
          total_tokens: 200
        )
      end

      it "displays both raw and rendered HTML" do
        visit raif.admin_model_completion_path(html_completion)

        expect(page).to have_content(I18n.t("raif.admin.common.raw"))
        expect(page).to have_content("<div><h1>Test</h1><p>HTML content</p></div>")

        expect(page).to have_content(I18n.t("raif.admin.common.rendered"))
        # The rendered HTML will be displayed in a div
        within(".border.p-3.bg-light") do
          expect(page).to have_css("h1", text: "Test")
          expect(page).to have_css("p", text: "HTML content")
        end
      end
    end
  end
end
