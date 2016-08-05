class CreateRtLogs < ActiveRecord::Migration
  def change
    create_table :rt_logs do |t|
      t.string :message

      t.timestamps
    end
    add_index :rt_logs, :message
  end
end
