class CreatePreContestants < ActiveRecord::Migration
  def change
    create_table :pre_contestants do |t|
      t.integer :user_id
      t.integer :contest_id

      t.timestamps
    end

    add_index :pre_contestants, [:user_id, :contest_id]
  end
end
