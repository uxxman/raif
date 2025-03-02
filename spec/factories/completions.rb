# frozen_string_literal: true

FactoryBot.define do
  factory :raif_completion, class: "Raif::Completion" do
    sequence(:prompt){|i| "prompt #{i} #{SecureRandom.hex(3)}" }
    sequence(:response){|i| "response #{i} #{SecureRandom.hex(3)}" }
    llm_model_name { Raif.available_llm_keys.sample.to_s }
  end

  factory :raif_conversation_entry_completion, parent: :raif_completion, class: "Raif::Completions::ConversationEntry" do
    type { "Raif::Completions::ConversationEntry" }
    raif_conversation_entry
  end
end
