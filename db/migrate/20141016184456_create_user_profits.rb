class CreateUserProfits < ActiveRecord::Migration
  def change
    create_table :user_profits do |t|
      t.integer :user_id
      t.decimal :hk_pnl, precision: 16, scale: 3, default: 0.0
      t.decimal :us_pnl, precision: 16, scale: 3, default: 0.0
      t.decimal :today_pnl, precision: 16, scale: 3, default: 0.0 #今日收益
      t.decimal :total_pnl, precision: 16, scale: 3, default: 0.0 #总收益

      t.date :date

      t.timestamps
    end
    
    add_index :user_profits, [:user_id, :date], unique: true
    add_index :user_profits, :user_id
    add_index :user_profits, :date
  end
end
