class Habit < ApplicationRecord
  belongs_to :user
  has_one :streakling_creature, dependent: :destroy

  validates :habit_name, presence: true
  validates :user_id, presence: true

  # Accept nested attributes for streakling creature
  accepts_nested_attributes_for :streakling_creature, allow_destroy: true

  # Every time a habit is created, a new Streakling is born
  after_create :ensure_streakling_creature!

  # Returns true if this habit was completed today (respects time machine)
  def completed_today?
    completed_on == current_effective_date
  end

  # Default emoji for habits (creature provides the main visual identity)
  def display_emoji
    "📝"
  end

  private

  def current_effective_date
    if defined?(TimeMachine) && TimeMachine.active?
      TimeMachine.simulated_date
    else
      Time.zone.today
    end
  end

  # Public method to ensure a habit has a streakling creature
  # Made public so it can be called from controllers and tests
  public
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
