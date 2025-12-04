class CreateStreaklingCreatures < ActiveRecord::Migration[7.0]
  def change
    create_table :streakling_creatures do |t|
      t.references :habit, null: false, foreign_key: true
      t.string  :name, default: "Little One"
      t.string  :animal_type, default: "dragon"
      t.integer :current_streak, default: 0
      t.integer :longest_streak, default: 0
      t.string  :mood, default: "happy"
      t.integer :consecutive_missed_days, default: 0
      t.boolean :is_dead, default: false
      t.date    :died_at
      t.integer :revived_count, default: 0
      t.string  :stage, default: "egg"

      t.timestamps
    end
  end
end
