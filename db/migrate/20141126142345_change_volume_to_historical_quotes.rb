class ChangeVolumeToHistoricalQuotes < ActiveRecord::Migration
  def change
    change_column :historical_quotes, :volume, :integer, limit: 8
  end
end
