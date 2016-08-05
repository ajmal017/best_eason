class ChangeViewableTypeOfArticle < ActiveRecord::Migration
  def change
    change_column :articles, :viewable, :boolean, default: true
  end
end
