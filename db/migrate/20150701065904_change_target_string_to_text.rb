class ChangeTargetStringToText < ActiveRecord::Migration
  def up
    change_column :target_messages, :target, :text
  end
  def down
    change_column :target_message, :target, :string
  end
end
