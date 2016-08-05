class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :orientations
      t.string :concerns
      t.string :professions
      t.integer :duration
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
