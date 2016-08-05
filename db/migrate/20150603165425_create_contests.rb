class CreateContests < ActiveRecord::Migration
  def change
    create_table :contests do |t|
      t.integer :status
      t.string :name
      t.datetime :start_at
      t.datetime :end_at
      t.integer :broker_id
      t.integer :users_count
      t.decimal :total_invest
      t.string :players_csv

      t.timestamps null: false
    end
  end
end
