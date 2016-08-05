class AddCurrentStepToPtApplications < ActiveRecord::Migration
  def change
    add_column :pt_applications, :current_step, :integer, default: 1
  end
end
