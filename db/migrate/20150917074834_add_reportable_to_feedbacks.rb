class AddReportableToFeedbacks < ActiveRecord::Migration

  def self.up
    add_column :feedbacks, :reportable_type, :string
    add_column :feedbacks, :reportable_id, :integer
    change_column :feedbacks, :feed_type, :integer, default: 0
  end

  def self.down
    remove_column :feedbacks, :reportable_type
    remove_column :feedbacks, :reportable_id
    change_column :feedbacks, :feed_type, :integer, default: 0
  end
end
