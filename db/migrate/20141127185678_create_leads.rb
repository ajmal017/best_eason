class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :username
      t.boolean :gender
      t.string :company
      t.string :mobile
      t.string :email
      t.string :weixin
      t.string :qq
      t.string :address
      t.integer :invitation_code_id
      t.integer :invite_user_id
      t.string :source

      t.timestamps
    end

    add_index :leads, :email
    add_index :leads, :invitation_code_id
    add_index :leads, :invite_user_id
  end
end
