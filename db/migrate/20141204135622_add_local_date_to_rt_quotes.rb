class AddLocalDateToRtQuotes < ActiveRecord::Migration
  def change
    add_column :rt_quotes, :local_date, :date
  end
end
