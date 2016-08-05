class CreateAdminLogs < ActiveRecord::Migration
  def change
    create_table :admin_logs do |t|
      t.integer :staffer_id
      t.string :content
      t.string :log_type
      t.string :request_ip

      t.timestamps null: false
    end
  end
end
