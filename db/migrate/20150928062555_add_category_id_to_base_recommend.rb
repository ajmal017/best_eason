class AddCategoryIdToBaseRecommend < ActiveRecord::Migration
  def change
    add_column :recommends, :category_id, :string
  end
end
