class CreateRoles < ActiveRecord::Migration
  
  def change
    create_table :roles do |t|
      t.string :name, null: false, limit: 50
      t.string :abbrev, null: false
      t.integer :position
      t.integer :staffers_count, default: 0
      t.string :description
      
      t.timestamps
    end

    add_index :roles, :position
    add_index :roles, :name
  
    Admin::Role.create!(name: '高级编辑', abbrev: 'senior_editor') 
    Admin::Role.create!(name: '网站编辑', abbrev: 'editor')
    Admin::Role.create!(name: '市场部', abbrev: 'sales')
    Admin::Role.create!(name: 'Ruby开发', abbrev: 'ruby')
  end

end
