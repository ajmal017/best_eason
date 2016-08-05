class AddInvitationLimitToInvitationCodes < ActiveRecord::Migration
  def change
    add_column :invitation_codes, :invitation_limit, :integer
  end
end
