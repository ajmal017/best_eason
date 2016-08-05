class CreateLandings < ActiveRecord::Migration
  def change
    create_table :landings do |t|
      t.string :email, null: false
      
      t.timestamps
    end
    
    add_index :landings, :email
  end
end
