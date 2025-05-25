# frozen_string_literal: true

class AddResponseFormatToRaifConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :raif_conversations, :response_format, :integer, default: 0, null: false
  end
end
