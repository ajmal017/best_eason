class AddChannelCodeToEmailTokens < ActiveRecord::Migration
  def change
    add_column :email_tokens, :channel_code, :string
  end
end
