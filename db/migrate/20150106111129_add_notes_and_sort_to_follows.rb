class AddNotesAndSortToFollows < ActiveRecord::Migration
  def change
    add_column :follows, :notes, :text
    add_column :follows, :sort, :float
  end
end