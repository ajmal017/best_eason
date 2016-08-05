class CreateActiveDocks < ActiveRecord::Migration
  def change
    create_table :active_docks do |t|
      t.string :name
      t.string :description
      t.string :short_id, limit: 50
      t.text :dock_date

      t.timestamps null: false
    end
  end
end
