# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Completions", type: :feature do
  let(:creator) { FB.create(:raif_test_user) }

  describe "index page" do
    let!(:completions) { FB.create_list(:raif_test_completion, 2, creator: creator) }
    let!(:completed_completion){ FB.create(:raif_test_completion, :completed, creator: creator) }
    let!(:failed_completion){ FB.create(:raif_test_completion, :failed, creator: creator) }
    let!(:in_progress_completion){ FB.create(:raif_test_completion, creator: creator, started_at: 1.minute.ago) }
    let!(:long_prompt_completion) do
      FB.create(:raif_test_completion, prompt: "a" * 200, creator: creator)
    end

    it "displays completions with all details, allows navigation, and handles edge cases" do
      visit raif.admin_completions_path

      # Check page title and table headers
      expect(page).to have_content(I18n.t("raif.admin.common.completions"))
      expect(page).to have_content(I18n.t("raif.admin.common.id"))
      expect(page).to have_content(I18n.t("raif.admin.common.created_at"))
      expect(page).to have_content(I18n.t("raif.admin.common.creator"))
      expect(page).to have_content(I18n.t("raif.admin.common.model"))
      expect(page).to have_content(I18n.t("raif.admin.common.status"))
      expect(page).to have_content(I18n.t("raif.admin.common.prompt"))

      # Check completions count and status badges
      expect(page).to have_css("tr.raif-completion", count: 6) # Total number of completions
      expect(page).to have_css(".badge.bg-success", text: I18n.t("raif.admin.common.completed"))
      expect(page).to have_css(".badge.bg-danger", text: I18n.t("raif.admin.common.failed"))
      expect(page).to have_css(".badge.bg-warning", text: I18n.t("raif.admin.common.in_progress"))
      expect(page).to have_css(".badge.bg-secondary", text: I18n.t("raif.admin.common.pending"))

      # Truncated long prompt
      expect(page).to have_content("a" * 97 + "...")

      # Test empty state
      Raif::Completion.delete_all
      visit raif.admin_completions_path
      expect(page).to have_content(I18n.t("raif.admin.common.no_completions"))
    end
  end

  describe "show page" do
    let!(:completion) do
      FB.create(
        :raif_test_completion,
        :completed,
        creator: creator,
        prompt: "Test prompt",
        response: "Test response",
        system_prompt: "You are a test assistant",
        llm_model_key: "open_ai_gpt_4o_mini"
      )
    end

    before do
      visit raif.admin_completion_path(completion)
    end

    it "displays the completion details and has a back link to the completions index" do
      expect(page).to have_content(I18n.t("raif.admin.completions.show.title", id: completion.id))

      # Check basic details
      expect(page).to have_content(completion.id.to_s)
      expect(page).to have_content(completion.creator_type)
      expect(page).to have_content(completion.creator_id.to_s)
      expect(page).to have_content("open_ai_gpt_4o_mini")
      expect(page).to have_content(completion.response_format)

      # Check timestamps
      expect(page).to have_content(completion.created_at.rfc822)
      expect(page).to have_content(completion.started_at.rfc822)
      expect(page).to have_content(completion.completed_at.rfc822)

      # Check prompt and response
      expect(page).to have_content("Test prompt")
      expect(page).to have_content("Test response")
      expect(page).to have_content("You are a test assistant")

      # Check back link functionality
      expect(page).to have_link(I18n.t("raif.admin.completions.show.back_to_completions"), href: raif.admin_completions_path)

      click_link I18n.t("raif.admin.completions.show.back_to_completions")
      expect(page).to have_current_path(raif.admin_completions_path)
    end

    context "with model_response" do
      let!(:model_response) do
        FB.create(
          :raif_model_response,
          source: completion,
          llm_model_key: completion.llm_model_key,
          raw_response: "Test model response",
          prompt_tokens: 1000,
          completion_tokens: 20,
          total_tokens: 1020
        )
      end

      it "displays the model_response section" do
        visit raif.admin_completion_path(completion)

        # Check model_response section exists
        expect(page).to have_content(I18n.t("raif.admin.common.model_response"))

        # Check model_response details
        expect(page).to have_link("##{model_response.id}", href: raif.admin_model_response_path(model_response))
        expect(page).to have_content(model_response.created_at.rfc822)
        expect(page).to have_content("1,000") # prompt_tokens
        expect(page).to have_content("20") # completion_tokens
        expect(page).to have_content("1,020") # total_tokens
      end
    end
  end
end
