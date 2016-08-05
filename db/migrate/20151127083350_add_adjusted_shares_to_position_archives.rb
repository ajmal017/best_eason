class AddAdjustedSharesToPositionArchives < ActiveRecord::Migration
  def change
    add_column :position_archives, :adjusted_shares, :float
  end
end