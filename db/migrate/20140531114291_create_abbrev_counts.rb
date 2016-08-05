class CreateAbbrevCounts < ActiveRecord::Migration
  def change
    create_table :abbrev_counts do |t|
      t.string :abbrev
      t.integer :sequence_number
      t.string :category, limit: 30

      t.timestamps
    end

    add_index :abbrev_counts, [:category, :abbrev], :unique => true
  end
end
