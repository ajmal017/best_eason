class AddLogoToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :logo, :string
  end
end
