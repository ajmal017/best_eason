class CreateForbiddenNames < ActiveRecord::Migration
  def change
    create_table :forbidden_names do |t|
      t.string :word
    end
  end
end