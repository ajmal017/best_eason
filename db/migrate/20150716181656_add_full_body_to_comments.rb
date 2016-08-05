class AddFullBodyToComments < ActiveRecord::Migration
  def change
    # 网站展示的body
    add_column :comments, :full_body, :text
    # 被回复的一级评论
    add_column :comments, :root_replyed_id, :integer
    # 被回复的以及评论的内容
    add_column :comments, :root_replyed_body, :text
  end
end
