class AddSuccCounterToTargetMessage < ActiveRecord::Migration
  def change
    add_column :target_messages, :succ_count, :integer
  end
end
