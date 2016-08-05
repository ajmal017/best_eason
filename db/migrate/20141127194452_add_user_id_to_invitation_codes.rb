class AddUserIdToInvitationCodes < ActiveRecord::Migration
  def change
    add_column :invitation_codes, :user_id, :integer
  end
end
