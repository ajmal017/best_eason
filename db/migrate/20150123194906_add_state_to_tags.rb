class AddStateToTags < ActiveRecord::Migration
  def change
    add_column :tags, :state, :integer, default: 0
    add_index :tags, :state
  end
end