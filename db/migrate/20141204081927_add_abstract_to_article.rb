class AddAbstractToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :abstract, :text
  end
end
