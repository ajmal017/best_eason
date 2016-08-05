class CreateBaskets < ActiveRecord::Migration
  def change
    create_table :baskets do |t|
      t.string :title
      t.text :description
      t.integer :author_id
      t.string :img
      t.string :segment
      t.datetime :start_on
      t.integer :scope
      t.boolean :custom
      t.integer :category
      t.integer :original_id
      
      t.text :abbrev
      t.integer :state,  default: 1
      t.boolean :third_party, default: true
      t.boolean :weight_changed, :defalut => false
      
      # return fields
      t.decimal :one_day_return, :precision => 13, :scale => 8
      t.decimal :one_month_return, :precision => 13, :scale => 8
      t.decimal :three_month_return, :precision => 13, :scale => 8
      t.decimal :one_year_return, :precision => 13, :scale => 8
      
      # counter cache
      t.integer :comments_count, defalut: 0
      t.integer :views_count, default: 0
      t.integer :orders_count, default: 0
      t.integer :likes_count, default: 0
      t.integer :follows_count, default: 0
      
      t.float :bullish_percent, default: 0
      t.float :hot_score, default: 0
      
      t.datetime :modified_at
      t.boolean :visible, default: false
      t.boolean :recommend, default: false
      t.decimal :orders_total_money, :precision => 16, :scale => 4, :default => 0
      t.string :type
      t.integer :parent_id
      t.date :archive_date
      t.float :bearish_percent, default: 0
      
      t.timestamps
    end
    
    add_index :baskets, :type
    add_index :baskets, :parent_id
    add_index :baskets, :original_id
    add_index :baskets, :orders_count
    add_index :baskets, :weight_changed
    add_index :baskets, :state
    add_index :baskets, :title
    add_index :baskets, :author_id
  end
end
