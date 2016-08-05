class CreateAccountPositionRisks < ActiveRecord::Migration

  def change
    create_table :account_position_risks do |t|
      # 个股集中度
      t.float :stock_focus_score, limit: 10
      # 一级行业集中度
      t.float :industry_focus_score, limit: 10
      # 板块集中度(中小板创业板)
      t.float :plate_focus_score, limit: 10
      
      t.integer :trading_account_id
      t.date :date

      t.timestamps
    end

    add_index :account_position_risks, [:trading_account_id, :date]
  end

end
