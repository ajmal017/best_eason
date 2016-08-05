class AddRequestIpToLandings < ActiveRecord::Migration
  def change
    add_column :landings, :request_ip, :string
  end
end
