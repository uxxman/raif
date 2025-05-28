# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::ModelTool, type: :model do
  describe "tool_arguments_schema" do
    it "returns the tool_arguments_schema" do
      expect(Raif::TestModelTool.tool_arguments_schema).to eq({
        type: "object",
        additionalProperties: false,
        required: ["items"],
        properties: {
          items: {
            type: "array",
            items: {
              type: "object",
              additionalProperties: false,
              properties: {
                title: { type: "string", description: "The title of the item" },
                description: { type: "string" },
              },
              required: ["title", "description"],
            }
          }
        }
      })
    end
  end
end
