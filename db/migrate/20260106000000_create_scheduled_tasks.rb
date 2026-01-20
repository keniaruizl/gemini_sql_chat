class CreateScheduledTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :gemini_sql_chat_scheduled_tasks do |t|
      t.references :user, null: false, index: true
      t.references :gemini_sql_chat_conversation, null: true, foreign_key: true, index: { name: 'index_scheduled_tasks_on_conversation_id' }
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
    # No agregamos índice de user_id aquí porque t.references ya lo crea automáticamente
  end
end
