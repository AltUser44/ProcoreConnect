class CreateSyncLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :sync_logs do |t|
      t.references :integration, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :response_code
      t.text :error_message

      t.timestamps
    end

    add_index :sync_logs, :status
    add_index :sync_logs, :event_type
    add_index :sync_logs, :created_at
  end
end
