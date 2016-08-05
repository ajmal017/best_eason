class AddIndexToApiTokens < ActiveRecord::Migration
  def change
    add_index :api_tokens, :access_token
    add_index :api_tokens, :user_id
  end
end
