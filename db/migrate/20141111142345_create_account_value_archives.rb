class CreateAccountValueArchives < ActiveRecord::Migration
  def change
    create_table :account_value_archives do |t|
      t.integer :user_id
      t.decimal :total_cash, precision: 16, scale: 3
      t.string :currency
      t.date :archive_date

      t.timestamps
    end
  end
end
