class CreateWebhookEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :webhook_events do |t|
      t.references :integration, null: false, foreign_key: true
      t.string :event_type
      t.jsonb :payload, null: false, default: {}
      t.boolean :processed, null: false, default: false
      t.datetime :processed_at

      t.timestamps
    end

    add_index :webhook_events, :processed
    add_index :webhook_events, :event_type
    add_index :webhook_events, :created_at
  end
end
