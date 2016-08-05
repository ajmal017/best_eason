class AddPositionToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :position, :float, default: 0.0
  end
end
