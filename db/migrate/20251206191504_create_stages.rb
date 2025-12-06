class CreateStages < ActiveRecord::Migration[7.1]
  def change
    create_table :stages do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :name, null: false
      t.integer :min_streak, null: false
      t.integer :max_streak, null: false
      t.text :default_message
      t.string :emoji
      t.integer :display_order, null: false, default: 0
      t.timestamps
    end

    add_index :stages, :display_order
    add_index :stages, [:min_streak, :max_streak]
  end
end
