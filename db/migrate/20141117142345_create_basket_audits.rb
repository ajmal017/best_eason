class CreateBasketAudits < ActiveRecord::Migration
  def change
    create_table :basket_audits do |t|
      t.integer :basket_id
      t.integer :category
      t.string :unpass_reason

      t.timestamps
    end
  end
end
