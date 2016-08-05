class AddSourceToRecommends < ActiveRecord::Migration
  def change
    add_column :recommends, :source, :string
    add_column :recommends, :category, :string
  end
end
