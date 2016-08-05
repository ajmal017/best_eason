class ChangeIbOrderIdOfOrderErrs < ActiveRecord::Migration
  def change
    change_column :order_errs, :ib_order_id, :string
  end
end
