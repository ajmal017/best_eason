class AddLandingIdToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :landing_id, :integer
  end
end
