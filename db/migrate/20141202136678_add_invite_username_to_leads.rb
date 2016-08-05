class AddInviteUsernameToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :invite_username, :string
  end
end
