class CreateSectors < ActiveRecord::Migration
  def up
    create_table :sectors do |t|
      t.string :name
      t.string :c_name

      t.timestamps
    end
    
    ::Sector::CATEGORY.each do |name, c_name|
      ::Sector.create!(name: name, c_name: c_name)
    end
  end
  
  def down
    drop_table :sectors
  end
end
