class DeleteCommentWorker
  @queue = :delete_comment_worker
  
  def self.perform(comment_id)
    Comment.find_by_id(comment_id).try(:delete_relative_records)
  end

end
