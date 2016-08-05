class AddTargetableToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :targetable_id, :integer
    add_column :notifications, :targetable_type, :string

    add_index :notifications, [:targetable_id, :targetable_type]
  end
end
