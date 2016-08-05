class CreateUserCounters < ActiveRecord::Migration
  def change
    create_table :user_counters do |t|
      t.integer :user_id
      t.string :type
      t.integer :amount, default: 0

      t.timestamps
    end

    add_index :user_counters, :user_id
    add_index :user_counters, :type
  end
end