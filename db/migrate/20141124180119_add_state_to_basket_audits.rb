class AddStateToBasketAudits < ActiveRecord::Migration
  def change
    add_column :basket_audits, :state, :integer, default: 0
  end
end