class CreateContestCashes < ActiveRecord::Migration
  def change
    create_table :contest_cashes do |t|
      t.references :contest
      t.decimal :value, precision: 16, scale: 2
      t.string :key

      t.timestamps null: false
    end
    add_index :contest_cashes, :contest_id
  end
end
