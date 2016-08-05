class CreateInvitationCodes < ActiveRecord::Migration
  def change
    create_table :invitation_codes do |t|
      t.string :code
      t.boolean :used, default: false 
      t.integer :lead_id

      t.timestamps
    end

    add_index :invitation_codes, :code
    add_index :invitation_codes, :lead_id
  end

end
