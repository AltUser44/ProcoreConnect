class ScopeIntegrationNameUniquenessToUser < ActiveRecord::Migration[7.2]
  def change
    remove_index :integrations, :name
    add_index    :integrations, %i[user_id name], unique: true
  end
end
