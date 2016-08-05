class CreateQuoteChanges < ActiveRecord::Migration
  # 记录ｙａｈｏｏ历史数据更新时间
  def change
    create_table :quote_changes do |t|
      t.string :symbol
      t.string :sign
      t.decimal :adj_close, precision: 16, scale: 3
      t.date :date

      t.timestamps
    end

    add_index :quote_changes, :symbol
    add_index :quote_changes, [:symbol, :date]
  end
end
