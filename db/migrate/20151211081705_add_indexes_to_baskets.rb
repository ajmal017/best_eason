class AddIndexesToBaskets < ActiveRecord::Migration
  def change
    add_index :baskets, [:type, :state, :market, :visible]
    
    add_index :taggings, [:tag_id, :taggable_id, :taggable_type]
  end
end
