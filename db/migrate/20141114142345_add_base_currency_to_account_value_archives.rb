class AddBaseCurrencyToAccountValueArchives < ActiveRecord::Migration
  def change
    add_column :account_value_archives, :base_currency, :string
  end
end
