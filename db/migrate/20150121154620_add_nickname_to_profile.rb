class AddNicknameToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :intro, :text
  end
end
