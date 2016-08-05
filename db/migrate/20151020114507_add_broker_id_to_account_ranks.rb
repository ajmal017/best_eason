class AddBrokerIdToAccountRanks < ActiveRecord::Migration
  def change
    add_column :account_ranks, :broker_id, :integer
  end
end
