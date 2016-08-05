class ChangeOriginFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :origin, :string
    add_column :users, :source, :string

    change_table :users do |t|
      t.change :mobile, :string, null: true, uniqueness: true
    end

    remove_index :users, :mobile
    add_index :users, :mobile, unique: true
  end
end
