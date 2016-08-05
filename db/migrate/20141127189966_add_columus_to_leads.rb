class AddColumusToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :user_id, :integer
    change_column :leads, :gender, :string
  end
end
