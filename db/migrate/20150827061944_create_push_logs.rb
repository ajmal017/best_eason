class CreatePushLogs < ActiveRecord::Migration
  def change
    create_table :push_logs do |t|
      t.string  :push_type, limit: 30
      t.string  :push_key, limit: 30
      t.integer :staffer_id
      t.text    :content
      t.text    :result
      t.integer :status, default: 0

      t.timestamps null: false
    end
  end
end
