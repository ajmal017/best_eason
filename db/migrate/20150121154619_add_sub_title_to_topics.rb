class AddSubTitleToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :sub_title, :string
  end
end