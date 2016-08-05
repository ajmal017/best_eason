class AddVar95ToAccountPositionRisks < ActiveRecord::Migration

  def change
    add_column :account_position_risks, :var95, :float
  end

end
