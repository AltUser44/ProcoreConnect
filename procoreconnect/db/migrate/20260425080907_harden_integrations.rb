class HardenIntegrations < ActiveRecord::Migration[7.2]
  def up
    # Existing integrations were created before multi-tenancy + webhook signing
    # were enforced. They have no user_id, no webhook_secret, and unencrypted
    # api_keys, so we clear them (and their dependent rows) and start fresh.
    say_with_time "Wiping pre-hardening integration data" do
      execute "DELETE FROM sync_logs"
      execute "DELETE FROM webhook_events"
      execute "DELETE FROM integrations"
    end

    add_reference :integrations, :user, foreign_key: true, null: false
    add_column    :integrations, :webhook_secret, :string, null: false
    add_index     :integrations, :webhook_secret, unique: true
  end

  def down
    remove_index  :integrations, :webhook_secret
    remove_column :integrations, :webhook_secret
    remove_reference :integrations, :user, foreign_key: true
  end
end
