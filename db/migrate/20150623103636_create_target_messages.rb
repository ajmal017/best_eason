class CreateTargetMessages < ActiveRecord::Migration
  def change
    create_table :target_messages do |t|
      t.text :content
      t.string :target

      t.timestamps null: false
    end
  end
end
