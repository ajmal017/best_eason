class AddTradingSinceToUserBindings < ActiveRecord::Migration
  
  def change
    add_column :user_bindings, :trading_since, :date
    add_column :user_bindings, :source, :string
  end

end
