class AddSmallLogoToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :small_logo, :string
  end
end
