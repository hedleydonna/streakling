class Habit < ApplicationRecord
  belongs_to :user

  scope :completed_today, -> { where(completed_on: Time.zone.today) }

  def completed_today?
    completed_on == Time.zone.today
  end

  def toggle_today!
    if completed_today?
      update!(completed_on: nil)
    else
      update!(completed_on: Time.zone.today)
      user.pet&.update_mood_and_streak!  # Critter reacts instantly!
    end
  end
end
