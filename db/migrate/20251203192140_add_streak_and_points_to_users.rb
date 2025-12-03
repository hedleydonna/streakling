class AddStreakAndPointsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :current_streak, :integer
    add_column :users, :longest_streak, :integer
    add_column :users, :last_completed_date, :date
    add_column :users, :daily_points, :integer
  end
end
