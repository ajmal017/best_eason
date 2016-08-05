class CreateBasketAdjustments < ActiveRecord::Migration
  def self.up
    create_table :basket_adjustments do |t|
      t.integer :prev_basket_id
      t.integer :next_basket_id
      t.integer :original_basket_id
      t.text :reason
      t.date :date
      t.timestamps
    end

    # add_index :basket_adjustments, :prev_basket_id
    # add_index :basket_adjustments, :next_basket_id
    add_index :basket_adjustments, :original_basket_id
  end

  def self.down
    drop_table :basket_adjustments
  end
end