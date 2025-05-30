# frozen_string_literal: true

class Raif::ApplicationRecord < ApplicationRecord
  include Raif::Concerns::BooleanTimestamp

  self.abstract_class = true

  scope :newest_first, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  def self.table_name_prefix
    "raif_"
  end
end
