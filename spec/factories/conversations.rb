# frozen_string_literal: true

FactoryBot.define do
  factory :raif_conversation, class: "Raif::Conversation" do
    creator factory: :raif_test_user

    trait :with_entries do
      transient do
        entries_count { 3 }
      end

      after(:create) do |conversation, evaluator|
        create_list(:raif_conversation_entry, evaluator.entries_count, :completed, raif_conversation: conversation)
      end
    end
  end

  factory :raif_test_conversation, class: "Raif::TestConversation", parent: :raif_conversation do
  end
end
