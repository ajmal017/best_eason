class ChangeEmailFromUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.change :email, :string, :null => true
    end
  end
end
