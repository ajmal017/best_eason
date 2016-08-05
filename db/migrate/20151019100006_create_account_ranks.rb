class CreateAccountRanks < ActiveRecord::Migration
  def change
    create_table :account_ranks do |t|
      t.integer :user_id
      t.integer :trading_account_id
      t.string :rank_type
      t.float :property
      t.float :percent
      t.date :date

      t.timestamps
    end

    add_index :account_ranks, :rank_type, length: 6
    add_index :account_ranks, [:trading_account_id, :rank_type], unique: true, name: "idx_account_ranks_type_ta_id", length: {rank_type: 6}
  end
end