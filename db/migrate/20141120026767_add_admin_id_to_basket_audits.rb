class AddAdminIdToBasketAudits < ActiveRecord::Migration
  def change
    add_column :basket_audits, :admin_id, :integer
  end
end
