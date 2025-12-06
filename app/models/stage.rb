class Stage < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :min_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :display_order, presence: true

  scope :ordered, -> { order(:display_order) }
  scope :for_streak, ->(streak) { where('min_streak <= ? AND max_streak >= ?', streak, streak) }

  # Find stage for a given streak value
  def self.stage_for_streak(streak)
    for_streak(streak).ordered.first || find_by(key: 'egg')
  end
end

