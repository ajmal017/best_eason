class CreateGuessIndices < ActiveRecord::Migration
  def change
    create_table :guess_indices do |t|
      t.references :user, index: true
      t.date :date, index: true
      t.decimal :index, precision: 8, scale: 2

      t.timestamps
    end
  end
end