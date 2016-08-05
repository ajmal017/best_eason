class AddMobileBodyToComments < ActiveRecord::Migration
  
  def change
    add_column :comments, :mobile_body, :text
  end

end
