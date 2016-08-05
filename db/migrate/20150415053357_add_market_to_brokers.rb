class AddMarketToBrokers < ActiveRecord::Migration
  def change
    add_column :brokers, :market, :string

    Broker.where(name: ["unicorn", "ib"]).update_all(market: "hk,us")
    Broker.where.not(name: ["unicorn", "ib"]).update_all(market: "cn")
  end
end