class CreateAppPermissions < ActiveRecord::Migration
  def change
    create_table :app_permissions do |t|
      t.integer :user_id
      t.boolean :all_following_stocks, null: false, default: true
      t.boolean :all_position_scale, null: false, default: true
      t.boolean :friend_position_scale, null: false, default: true
    end
  end
end
