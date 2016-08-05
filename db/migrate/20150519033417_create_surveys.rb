class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.integer :q1_1
      t.string :q1_2
      t.boolean :q2
      t.integer :q3_1
      t.integer :q3_2
      t.integer :q3_3
      t.integer :q3_4
      t.string :q3_5
      t.text :q4
      t.text :q5
      t.string :user_name
      t.string :user_gender
      t.string :user_phone

      t.timestamps null: false
    end
  end
end
