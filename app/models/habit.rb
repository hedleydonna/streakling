class Habit < ApplicationRecord
  belongs_to :user
  has_one :streakling_creature, dependent: :destroy

  # Accept nested attributes for streakling creature
  accepts_nested_attributes_for :streakling_creature

  # Every time a habit is created, a new Streakling is born
  after_create :ensure_streakling_creature!

  # Returns true if this habit was completed today
  def completed_today?
    completed_on == Time.zone.today
  end

  private

  def ensure_streakling_creature!
    # Only create if one doesn't already exist (e.g., when created via nested attributes)
    return if streakling_creature.present?

    create_streakling_creature!(
      streakling_name: "Little One",
      animal_type: "dragon",
      current_streak: 0,
      longest_streak: 0,
      mood: "happy",
      consecutive_missed_days: 0,
      is_dead: false,
      revived_count: 0,
      stage: "egg"
    )
  end
end
