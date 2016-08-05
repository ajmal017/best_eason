class AddFinishedToUserProfits < ActiveRecord::Migration
  def change
    add_column :user_profits, :finished, :boolean, default: false
  end
end
