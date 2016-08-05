class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.references :user
      t.text :content
      t.integer :feed_type
      t.string :contact_way
    end
  end
end