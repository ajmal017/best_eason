class DeleteInvitationCodeIdFromLeads < ActiveRecord::Migration
  def change
    remove_column :leads, :invitation_code_id
  end
end

