class CreateScheduledTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :gemini_sql_chat_scheduled_tasks do |t|
      t.references :user, null: false
      t.references :conversation, null: true, foreign_key: { to_table: :gemini_sql_chat_conversations }
      t.string :name, null: false
      t.text :question, null: false
      t.string :schedule_type, null: false # 'interval' o 'cron'
      t.integer :interval_seconds # Para schedule_type = 'interval'
      t.string :cron_expression # Para schedule_type = 'cron'
      t.datetime :next_run_at, null: false
      t.datetime :last_run_at
      t.integer :run_count, default: 0
      t.boolean :active, default: true
      t.text :last_result
      t.text :last_error
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :gemini_sql_chat_scheduled_tasks, :deleted_at
    add_index :gemini_sql_chat_scheduled_tasks, :next_run_at
    add_index :gemini_sql_chat_scheduled_tasks, :active
    add_index :gemini_sql_chat_scheduled_tasks, :user_id
  end
end
