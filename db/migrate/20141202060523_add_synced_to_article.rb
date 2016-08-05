class AddSyncedToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :synchronized, :boolean, default: false
  end
end
