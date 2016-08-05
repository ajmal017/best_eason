class CreateCategories < ActiveRecord::Migration
  def up
    create_table :categories do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
    
    Category::ARTICLE.each do |code, name|
      Category.create(name: name, code: code)
    end
  end
  
  def down
    drop_table :categories
  end
end
