class AddTopCommentableToComments < ActiveRecord::Migration

  # 评论改版
  def change
    # 被顶级回复的对象
    add_column :comments, :top_commentable_id, :integer
    add_column :comments, :top_commentable_type, :string, :limit => 30
    
    add_index :comments, [:top_commentable_id, :top_commentable_type]

    # 改评论的所有父节点ids集合
    add_column :comments, :commentable_ids, :string, limit: 512

    add_index :comments, :commentable_ids, length: 120
  end

end
