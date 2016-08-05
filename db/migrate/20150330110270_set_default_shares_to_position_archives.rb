class SetDefaultSharesToPositionArchives < ActiveRecord::Migration

  def change
    change_column_default :position_archives, :shares, 0.0 
  end

end
