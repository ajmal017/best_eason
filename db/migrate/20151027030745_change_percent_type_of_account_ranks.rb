class ChangePercentTypeOfAccountRanks < ActiveRecord::Migration
  def change
    change_column :account_ranks, :percent, :decimal, precision: 10, scale: 5
  end
end
