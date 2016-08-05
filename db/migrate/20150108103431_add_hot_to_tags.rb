class AddHotToTags < ActiveRecord::Migration
  def change
    add_column :tags, :hot, :boolean, default: false
  end
end
