class RemoveFocusFromHabits < ActiveRecord::Migration[7.1]
  def change
    remove_column :habits, :focus, :boolean
  end
end
