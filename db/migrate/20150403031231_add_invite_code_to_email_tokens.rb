class AddInviteCodeToEmailTokens < ActiveRecord::Migration
  def change
    add_column :email_tokens, :invite_code, :string
  end
end
