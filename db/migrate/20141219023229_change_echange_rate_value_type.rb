class ChangeEchangeRateValueType < ActiveRecord::Migration
  def change
    change_column :exchange_rates, :value, :decimal, precision: 16, scale: 10
  end
end
