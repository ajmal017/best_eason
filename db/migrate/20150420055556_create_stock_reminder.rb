class CreateStockReminder < ActiveRecord::Migration
  def change
    create_table :stock_reminders do |t|
      t.integer :user_id, null: false
      t.integer :stock_id, null: false
      t.string  :reminder_type, null: false    # up down scale
      t.float   :reminder_value
    end

    add_index :stock_reminders, :user_id
    add_index :stock_reminders, [:user_id, :stock_id, :reminder_type], unique: true
  end
end
