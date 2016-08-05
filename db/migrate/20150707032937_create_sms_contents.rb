class CreateSmsContents < ActiveRecord::Migration
  def change
    create_table :sms_contents do |t|
      t.string :phone
      t.text :msg_content
      t.string :sp_number

      t.timestamps null: false
    end
  end
end
