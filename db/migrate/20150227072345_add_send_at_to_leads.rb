class AddSendAtToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :send_at, :datetime
  end
end
