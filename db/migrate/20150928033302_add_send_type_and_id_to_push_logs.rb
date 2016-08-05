class AddSendTypeAndIdToPushLogs < ActiveRecord::Migration
  def change
    add_column :push_logs, :mentionable_type, :string
    add_column :push_logs, :mentionable_id, :string
  end
end
