class CreateChannelCodes < ActiveRecord::Migration
  def change
    create_table :channel_codes do |t|
      t.string :code, limit: 50
      t.string :apk_url
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :channel_codes, :code, name: 'channel_codes_code'
  end
end
