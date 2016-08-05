class ChangeOrderErrMessageType < ActiveRecord::Migration
  def change
    change_column :order_errs, :message, :text
  end
end
