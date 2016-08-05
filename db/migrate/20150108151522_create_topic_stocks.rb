class CreateTopicStocks < ActiveRecord::Migration
  def change
    create_table :topic_stocks do |t|
      t.references :topic
      t.references :base_stock
      t.float :position, default: 10000

      t.timestamps
    end
  end
end