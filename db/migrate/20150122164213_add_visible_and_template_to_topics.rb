class AddVisibleAndTemplateToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :visible, :boolean, default: false
    add_column :topics, :template, :string
  end
end