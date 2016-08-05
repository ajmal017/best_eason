class CreateUserDayProperties < ActiveRecord::Migration
  def change
    create_table :user_day_properties do |t|
      t.integer :user_id
      t.date :date
      t.decimal :total, precision: 16, scale: 4
      # total_cash 可在每日早晨5点先跑任务记录当时cash
      t.decimal :total_cash, precision: 16, scale: 4
      # 抓取到quotes后，再计算stocks cost 和 total
      t.decimal :total_stocks_cost, precision: 16, scale: 4
      t.string :base_currency

      t.timestamps
    end
    
    add_index :user_day_properties, :user_id
    add_index :user_day_properties, [:user_id, :date]
  end
end