class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :content
      t.integer :user_id
      t.references :commentable, polymorphic: {limit: 16}
      t.integer :likes_count
      t.integer :comments_count
      # 是否看涨
      t.boolean :bullish
      
      t.references :replyable, polymorphic: {limit: 16}

      t.timestamps
    end

    add_index :comments, [:replyable_id, :replyable_type]
    add_index :comments, :user_id
    add_index :comments, [:commentable_id, :commentable_type]
  end
end