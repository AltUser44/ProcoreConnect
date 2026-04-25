class CreateIntegrations < ActiveRecord::Migration[7.2]
  def change
    create_table :integrations do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.string :webhook_url
      t.string :api_endpoint, null: false
      t.string :api_key
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :integrations, :name, unique: true
    add_index :integrations, :status
  end
end
