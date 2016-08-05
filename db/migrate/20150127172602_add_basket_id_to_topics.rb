class AddBasketIdToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :basket_id, :integer
  end
end