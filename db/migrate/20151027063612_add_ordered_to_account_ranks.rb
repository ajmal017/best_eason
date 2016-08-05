class AddOrderedToAccountRanks < ActiveRecord::Migration
  def change
    add_column :account_ranks, :ordered, :boolean, default: false
  end
end
