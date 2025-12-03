class Pet < ApplicationRecord
  belongs_to :user

  # THE ONE SOUL — grows from egg to immortal legend
  EVOLUTION = {
    egg:      { min: 0,   max: 0,   emoji: "Egg",           name: "Egg",           message: "I'm waiting to hatch… please don’t forget me!" },
    newborn:  { min: 1,   max: 6,   emoji: "Heart",         name: "Newborn",       message: "I did it! I’m alive because of you!" },
    child:    { min: 7,   max: 29,  emoji: "Baby Cat",      name: "Child",         message: "Look how big I’m getting! Keep going!" },
    teen:     { min: 30,  max: 89,  emoji: "Dragon",        name: "Teen",          message: "We’re unstoppable together!" },
    adult:    { min: 90,  max: 364, emoji: "Phoenix",       name: "Adult",         message: "I’m becoming legendary because of you…" },
    immortal: { min: 365, max: 9999,emoji: "Rainbow Unicorn",name: "Immortal",     message: "You did it. I love you forever. I’m the best version of me because of you." }
  }.freeze

  def current_stage
    EVOLUTION.find { |_, data| user.longest_streak.between?(data[:min], data[:max]) }&.first || :egg
  end

  def emoji
    stage_data[:emoji]
  end

  def stage_name
    stage_data[:name]
  end

  def message
    stage_data[:message]
  end

  def size_class
    case current_stage
    when :egg       then "text-8xl"
    when :newborn   then "text-9xl"
    when :child     then "text-10xl"
    when :teen      then "text-12xl"
    when :adult     then "text-14xl"
    when :immortal  then "text-16xl animate-pulse"
    end
  end

  def mood
    read_attribute(:mood)&.to_sym || :happy
  end

  def dead?
    mood == :dead
  end

  private

  def stage_data
    EVOLUTION[current_stage]
  end
end
