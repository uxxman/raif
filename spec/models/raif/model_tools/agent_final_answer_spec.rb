# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelTools::AgentFinalAnswer do
  describe "#tool_arguments_schema" do
    it "validates against rules" do
      llm = Raif.llm(:bedrock_nova_pro)
      expect(llm.validate_json_schema!(described_class.tool_arguments_schema)).to eq(true)
    end
  end
end
