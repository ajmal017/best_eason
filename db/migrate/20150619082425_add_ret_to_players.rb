class AddRetToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :ret, :float
  end
end
