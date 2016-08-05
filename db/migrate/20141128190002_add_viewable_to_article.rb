class AddViewableToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :viewable, :boolean, default: false
  end
end
