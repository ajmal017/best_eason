class AddRelatedStocksAndRelatedBasketsToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :related_stocks, :text
    add_column :articles, :related_baskets, :text
  end
end
