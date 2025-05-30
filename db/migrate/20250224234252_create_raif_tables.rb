# frozen_string_literal: true

class CreateRaifTables < ActiveRecord::Migration[7.1]
  def change
    create_table :raif_tasks do |t|
      t.string :type, null: false, index: true
      t.text :prompt
      t.text :raw_response
      t.references :creator, polymorphic: true, null: false, index: true
      t.text :system_prompt
      t.string :requested_language_key
      t.integer :response_format, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.jsonb :available_model_tools, null: false
      t.string :llm_model_key, null: false

      t.timestamps
    end

    create_table :raif_conversations do |t|
      t.string :llm_model_key, null: false
      t.references :creator, polymorphic: true, null: false, index: true
      t.string :requested_language_key
      t.string :type, null: false
      t.text :system_prompt
      t.jsonb :available_model_tools, null: false
      t.jsonb :available_user_tools, null: false
      t.integer :conversation_entries_count, default: 0, null: false
      t.integer :response_format, :integer, default: 0, null: false

      t.timestamps
    end

    create_table :raif_conversation_entries do |t|
      t.references :raif_conversation, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :user_message
      t.text :raw_response
      t.text :model_response_message

      t.timestamps
    end

    create_table :raif_model_tool_invocations do |t|
      t.references :source, polymorphic: true, null: false, index: true
      t.string :tool_type, null: false
      t.jsonb :tool_arguments, null: false
      t.jsonb :result, null: false
      t.datetime :completed_at
      t.datetime :failed_at

      t.timestamps
    end

    create_table :raif_user_tool_invocations do |t|
      t.references :raif_conversation_entry, null: false, foreign_key: true
      t.string :type, null: false
      t.jsonb :tool_settings, null: false

      t.timestamps
    end

    create_table :raif_agents do |t|
      t.string :type, null: false
      t.string :llm_model_key, null: false
      t.text :task
      t.text :system_prompt
      t.text :final_answer
      t.integer :max_iterations, default: 10, null: false
      t.integer :iteration_count, default: 0, null: false
      t.jsonb :available_model_tools, null: false
      t.references :creator, polymorphic: true, null: false, index: true
      t.string :requested_language_key
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :failure_reason
      t.jsonb :conversation_history, null: false

      t.timestamps
    end

    create_table :raif_model_completions do |t|
      t.references :source, polymorphic: true, index: true
      t.string :llm_model_key, null: false
      t.string :model_api_name, null: false
      t.jsonb :available_model_tools, null: false
      t.jsonb :messages, null: false
      t.text :system_prompt
      t.integer :response_format, default: 0, null: false
      t.string :response_format_parameter
      t.decimal :temperature, precision: 5, scale: 3
      t.integer :max_completion_tokens
      t.integer :completion_tokens
      t.integer :prompt_tokens
      t.text :raw_response
      t.jsonb :response_tool_calls
      t.integer :total_tokens
      t.decimal :prompt_token_cost, precision: 10, scale: 6
      t.decimal :output_token_cost, precision: 10, scale: 6
      t.decimal :total_cost, precision: 10, scale: 6
      t.integer :retry_count, default: 0, null: false

      t.timestamps
    end

    add_index :raif_model_completions, :created_at
    add_index :raif_tasks, :created_at
    add_index :raif_conversations, :created_at
    add_index :raif_conversation_entries, :created_at
    add_index :raif_agents, :created_at

    add_index :raif_tasks, [:type, :completed_at]
    add_index :raif_tasks, [:type, :failed_at]
    add_index :raif_tasks, [:type, :started_at]
  end

end
