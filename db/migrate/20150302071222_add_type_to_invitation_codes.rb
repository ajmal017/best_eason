class AddTypeToInvitationCodes < ActiveRecord::Migration
  def change
    add_column :invitation_codes, :type, :string
    add_index :invitation_codes, :type
  end
end
