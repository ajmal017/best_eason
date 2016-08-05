class CreateArticleStocks < ActiveRecord::Migration
  def change
    create_table :article_stocks do |t|
      t.integer :article_id
      t.integer :stock_id

      t.timestamps
    end
    
    add_index :article_stocks, [:article_id, :stock_id], unique: true
    add_index :article_stocks, :stock_id
  end
end
