class AddFailCounterToTargetMessage < ActiveRecord::Migration
  def change
    add_column :target_messages, :fail_count, :integer
  end
end
