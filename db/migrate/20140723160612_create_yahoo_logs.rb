class CreateYahooLogs < ActiveRecord::Migration
  def change
    create_table :yahoo_logs do |t|
      t.integer :base_id
      t.string :code
      t.text :message
      
      t.timestamps
    end
  end
end
