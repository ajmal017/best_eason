class AddNewsIdToRecommends < ActiveRecord::Migration
  def change
    add_column :recommends, :news_id, :string
  end
end
