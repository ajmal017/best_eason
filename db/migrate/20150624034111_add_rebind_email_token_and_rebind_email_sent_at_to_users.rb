class AddRebindEmailTokenAndRebindEmailSentAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :rebind_email, :string
    add_column :users, :rebind_email_token, :string
    add_column :users, :rebind_email_sent_at, :datetime
  end
end
