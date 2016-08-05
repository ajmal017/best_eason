class AddProfitToAccountRanks < ActiveRecord::Migration
  def change
    add_column :account_ranks, :profit, :float, default: 0
  end
end
