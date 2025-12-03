class AddFocusToHabits < ActiveRecord::Migration[7.1]
  def change
    add_column :habits, :focus, :boolean, default: false
  end
end
