class AddCommentsCountStaticContents < ActiveRecord::Migration

  def change
    add_column :static_contents, :comments_count, :integer, default: 0
  end

end
