class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :habits, dependent: :destroy

  # Current streak: how many consecutive perfect days ending today
  def current_streak
    return 0 unless habits.any?

    streak = 0
    date = Time.zone.today

    loop do
      # Did the user complete ALL habits on this date?
      if perfect_day?(date)
        streak += 1
        date -= 1.day
      else
        break
      end
    end

    streak
  end

  # Longest streak ever
  def longest_streak
    return 0 unless habits.any?

    max_streak = 0
    current = 0
    date = habits.minimum(:completed_on)&.to_date || Time.zone.today

    # Scan from the very first habit completion to today
    (date..Time.zone.today).each do |d|
      if perfect_day?(d)
        current += 1
        max_streak = [max_streak, current].max
      else
        current = 0
      end
    end

    max_streak
  end

  # Total number of perfect days ever
  def total_perfect_days
    (habits.minimum(:completed_on)&.to_date || Time.zone.today..Time.zone.today)
      .count { |date| perfect_day?(date) }
  end

  def admin?
    admin
  end

  private

  # Was every habit completed on this exact date?
  def perfect_day?(date)
    # Count how many habits exist that were supposed to be done by this date
    # (simplest: all habits ever created — you can refine later)
    total_habits = habits.count
    completed_that_day = habits.where(completed_on: date).count

    completed_that_day == total_habits && total_habits > 0
  end
end
