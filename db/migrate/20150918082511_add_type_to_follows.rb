class AddTypeToFollows < ActiveRecord::Migration
  def change
    add_column :follows, :type, :string
  end
end
