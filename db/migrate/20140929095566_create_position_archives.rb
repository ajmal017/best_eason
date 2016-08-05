class CreatePositionArchives < ActiveRecord::Migration
  def change
    create_table :position_archives do |t|
      t.integer :user_id
      t.string :instance_id
      t.integer :base_stock_id
      t.date :archive_date
      t.integer :area
      t.decimal :shares, precision: 16, scale: 2
      t.integer :basket_id
      t.decimal :basket_mount, precision: 16, scale: 2
      t.decimal :average_cost, precision: 16, scale: 10, default: 0.0
      t.integer :pending_shares
      t.string :updated_by

      t.timestamps
    end

    add_index :position_archives, [:instance_id, :base_stock_id, :user_id, :archive_date], name: 'unique_index_position_archives', unique: true
    add_index :position_archives, :user_id
    add_index :position_archives, :instance_id
    add_index :position_archives, :archive_date
    add_index :position_archives, :area
  end
end
