class AddInvitedToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :invited, :boolean, default: false
  end
end
