# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :raif_test_users do |t|
      t.string :email

      t.timestamps
    end
  end
end
