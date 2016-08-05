class AddBigImgToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :big_img, :string
  end
end