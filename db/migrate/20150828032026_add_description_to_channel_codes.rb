class AddDescriptionToChannelCodes < ActiveRecord::Migration
  def change
    add_column :channel_codes, :description, :string
    add_column :channel_codes, :media, :string, limit: 50
    add_column :channel_codes, :ad_type, :string, limit: 50
  end
end
