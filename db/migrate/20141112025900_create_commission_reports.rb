class CreateCommissionReports < ActiveRecord::Migration
  def change
    create_table :commission_reports do |t|
      t.decimal :commission, precision: 16, scale: 4
      t.string :currency
      t.string :exec_id
      t.string :realized_pnl
      t.string :yield
      t.string :yield_redemption_date

      t.timestamps
    end
  end
end
