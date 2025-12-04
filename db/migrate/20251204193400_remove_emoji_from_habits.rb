class RemoveEmojiFromHabits < ActiveRecord::Migration[7.1]
  def change
    remove_column :habits, :emoji, :string
  end
end
