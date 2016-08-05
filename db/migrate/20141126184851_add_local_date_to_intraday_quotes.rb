class AddLocalDateToIntradayQuotes < ActiveRecord::Migration
  def change
    add_column :intraday_quotes, :local_date, :date
  end
end