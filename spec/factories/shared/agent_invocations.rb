# frozen_string_literal: true

FactoryBot.define do
  factory :raif_agent_invocation, class: "Raif::AgentInvocation" do
    task { "What is the capital of France?" }
    llm_model_key { Raif.available_llm_keys.sample.to_s }
    available_model_tools { ["Raif::TestModelTool"] }
  end

  factory :raif_native_tool_calling_agent_invocation, parent: :raif_agent_invocation, class: "Raif::AgentInvocations::NativeToolCallingAgent" do
  end

  factory :raif_re_act_agent_invocation, parent: :raif_agent_invocation, class: "Raif::AgentInvocations::ReActAgent" do
  end
end
