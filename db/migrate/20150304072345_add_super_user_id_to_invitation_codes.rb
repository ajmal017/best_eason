class AddSuperUserIdToInvitationCodes < ActiveRecord::Migration
  def change
    add_column :invitation_codes, :super_user_id, :integer

    add_index :invitation_codes, :super_user_id
  end
end
