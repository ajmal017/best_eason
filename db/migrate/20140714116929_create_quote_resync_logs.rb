class CreateQuoteResyncLogs < ActiveRecord::Migration
  def change
    # 同步quote日志表
    create_table :quote_resync_logs do |t|
      t.string :symbol, null: false
      t.integer :category
      t.integer :base_id
      t.decimal :old_adj_close, precision: 16, scale: 3
      t.decimal :new_adj_close, precision: 16, scale: 3
      t.boolean :kline, default: false
      
      t.timestamps
    end
    
    add_index :quote_resync_logs, [:base_id, :kline]
  end
end
