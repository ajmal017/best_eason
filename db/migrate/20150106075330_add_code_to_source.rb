class AddCodeToSource < ActiveRecord::Migration
  def change
    add_column :sources, :code, :string
  end
end
