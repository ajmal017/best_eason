class AddSnCodeToApiTokens < ActiveRecord::Migration
  def change
    add_column :api_tokens, :sn_code, :string
  end
end
