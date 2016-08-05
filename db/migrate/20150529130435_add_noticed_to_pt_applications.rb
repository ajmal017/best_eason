class AddNoticedToPtApplications < ActiveRecord::Migration
  def change
    add_column :pt_applications, :noticed, :boolean, default: false
  end
end
