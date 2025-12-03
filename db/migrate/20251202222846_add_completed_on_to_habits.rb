class AddCompletedOnToHabits < ActiveRecord::Migration[7.1]
  def change
    add_column :habits, :completed_on, :date
  end
end
