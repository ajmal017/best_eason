class CreatePtApplications < ActiveRecord::Migration
  def change
    create_table :pt_applications do |t|
      t.string :user_id
      t.integer :status, default: 0
      t.string :mobile
      t.integer :q1
      t.integer :q2
      t.integer :q3
      t.string :q4
      t.text :q5
      t.text :q6
      t.text :q7
      t.text :q8
      t.text :q9

      t.string :name
      t.string :id_no
      t.string :industry
      t.string :com_name
      t.string :bank_name
      t.string :card_no

      t.timestamps null: false
    end
  end
end
