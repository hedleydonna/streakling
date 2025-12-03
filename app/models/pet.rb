class Pet < ApplicationRecord
  belongs_to :user

  # Evolution stages (unchanged — still perfect)
  EVOLUTION = {
    egg:      { min: 0,   max: 0,   emoji: "Egg",           name: "Egg",           message: "I'm waiting to hatch… please don’t forget me!" },
    newborn:  { min: 1,   max: 6,   emoji: "Heart",         name: "Newborn",       message: "I did it! I’m alive because of you!" },
    child:    { min: 7,   max: 29,  emoji: "Baby Cat",      name: "Child",         message: "Look how big I’m getting! Keep going!" },
    teen:     { min: 30,  max: 89,  emoji: "Dragon",        name: "Teen",          message: "We’re unstoppable together!" },
    adult:    { min: 90,  max: 364, emoji: "Phoenix",       name: "Adult",         message: "I’m becoming legendary because of you…" },
    immortal: { min: 365, max: 9999,emoji: "Rainbow Unicorn",name: "Immortal",     message: "You did it. I love you forever. I’m the best version of me because of you." }
  }.freeze

  # ——————————————————————————————
  # CORE: Daily Score → Real Streak Growth
  # ——————————————————————————————
  def update_mood_and_streak!
    habits = user.habits
    total = habits.count
    completed_today = habits.where(completed_on: Time.zone.today).count
  
    # Safety first
    user.reload
    daily_points = user.daily_points || 0
    current_streak = user.current_streak || 0
    longest_streak = user.longest_streak || 0
  
    return update!(mood: :happy) if total.zero?
  
    percentage = (completed_today * 100.0 / total).round
    points_earned_today = completed_today
  
    # 1. Mood (unchanged)
    new_mood = case percentage
               when 100          then :happy
               when 70..99       then :okay
               when 40..69       then :sad
               when 1..39        then :sick
               else                   :dead
               end
  
    # 2. Add points
    new_daily_points = daily_points + points_earned_today
  
    # 3. Calculate effective streak days (10 points = 1 day)
    effective_days = new_daily_points / 10
  
    # 4. Update user
    user.update!(
      daily_points: new_daily_points,
      current_streak: effective_days,
      longest_streak: [longest_streak, effective_days].max
    )
  
    # 5. Resurrection
    if new_mood != :dead && mood == :dead && effective_days >= 7
      update!(mood: :happy, level: level + 20)
      flash[:resurrected] = true
      return
    end
  
    update!(mood: new_mood) if mood != new_mood
  end

  # ——————————————————————————————
  # Rest of your methods (unchanged)
  # ——————————————————————————————
  def current_stage
    EVOLUTION.find { |_, data| user.longest_streak.between?(data[:min], data[:max]) }&.first || :egg
  end

  def emoji; stage_data[:emoji]; end
  def stage_name; stage_data[:name]; end
  def message; stage_data[:message]; end

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

  def mood; read_attribute(:mood)&.to_sym || :happy; end
  def dead?; mood == :dead; end

  private
  def stage_data; EVOLUTION[current_stage]; end
end
