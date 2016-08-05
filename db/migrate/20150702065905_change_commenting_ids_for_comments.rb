class ChangeCommentingIdsForComments < ActiveRecord::Migration

  def change
    #if index_exists?(:comments, :commenting_ids)
    #  remove_index :comments, :commenting_ids
    #end
    #rename_column :comments, :commenting_ids, :commentable_ids
    #add_index :comments, :commentable_ids, length: 255
  end

end
