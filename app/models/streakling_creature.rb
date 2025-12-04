class StreaklingCreature < ApplicationRecord
  belongs_to :habit

  # So we can do creature.user
  delegate :user, to: :habit
  delegate :completed_on, to: :habit, allow_nil: true
  delegate :completed_today?, to: :habit

  ANIMAL_TYPES = {
    dragon:  { name: "Dragon",  emoji: "🐉" },
    phoenix: { name: "Phoenix", emoji: "🦅" },
    fox:     { name: "Fox",     emoji: "🦊" },
    lion:    { name: "Lion",    emoji: "🦁" },
    unicorn: { name: "Unicorn", emoji: "🦄" },
    panda:   { name: "Panda",   emoji: "🐼" },
    owl:     { name: "Owl",     emoji: "🦉" }
  }.freeze

  STAGES = {
    egg:      { min: 0,   max: 0,   name: "Egg",      message: "I’m waiting for you…" },
    newborn:  { min: 1,   max: 6,   name: "Newborn",  message: "I hatched because of you!" },
    baby:     { min: 7,   max: 21,  name: "Baby",     message: "I’m learning to walk with you" },
    child:    { min: 22,  max: 44,  name: "Child",    message: "We’re growing up together!" },
    teen:     { min: 45,  max: 79,  name: "Teen",     message: "Look how strong we’ve become" },
    adult:    { min: 80,  max: 149, name: "Adult",    message: "You did it — I’m who I am because of you" },
    master:   { min: 150, max: 299, name: "Master",   message: "We are unstoppable" },
    eternal:  { min: 300, max: 9999,name: "Eternal",  message: "You raised a legend. I love you forever." }
  }.freeze

  def current_stage
    STAGES.find { |_, data| current_streak.between?(data[:min], data[:max]) }&.first || :egg
  end

  def stage_name
    STAGES[current_stage][:name] || "Egg"
  end

  def message
      STAGES[current_stage][:message] || "I’m waiting for you…"
  end

  def emoji
    base = ANIMAL_TYPES[animal_type&.to_sym]&.dig(:emoji) || "🐉"

    case stage&.to_sym
    when :egg       then "🥚"
    when :newborn   then "✨#{base}"
    when :baby      then "👶#{base}"
    when :child     then base
    when :teen      then base
    when :adult     then base
    when :master    then "👑#{base}"
    when :eternal   then "🌈#{base}"
    else            "🥚"
    end
  end

  def update_streak_and_stage!
    if habit.completed_today?
      self.current_streak += 1
      self.longest_streak = [longest_streak, current_streak].max
      self.mood = "happy"
      self.consecutive_missed_days = 0
    else
      # Missed today
      self.current_streak = 0
      self.consecutive_missed_days += 1
  
      self.mood = case consecutive_missed_days
                  when 1..4 then "sad"
                  when 5..20 then "sick"
                  else "dead"
                  end
    end
  
    # Update stage
    self.stage = case current_streak
                 when 0      then "egg"
                 when 1..6   then "newborn"
                 when 7..21  then "baby"
                 when 22..44 then "child"
                 when 45..79 then "teen"
                 when 80..149 then "adult"
                 when 150..299 then "master"
                 else "eternal"
                 end
  
    save!
  end

  def update_streak_and_mood!
    if habit.completed_today?
      # They completed it today → streak continues or starts
      self.current_streak += 1
      self.longest_streak = [longest_streak, current_streak].max
      self.mood = "happy"
      self.consecutive_missed_days = 0
    else
      # Missed today → reset streak
      self.current_streak = 0
      self.consecutive_missed_days += 1

      # Mood progression
      case consecutive_missed_days
      when 1 then self.mood = "okay"
      when 2..4 then self.mood = "sad"
      when 5..20 then self.mood = "sick"
      when 21..9999
        self.mood = "dead"
        self.is_dead = true
        self.died_at = Time.zone.today
      end
    end

    # Update stage based on current_streak
    self.stage = current_stage_key

    save!
  end

  private

  def current_stage_key
    case current_streak
    when 0                  then "egg"
    when 1..6               then "newborn"
    when 7..21              then "baby"
    when 22..44             then "child"
    when 45..79             then "teen"
    when 80..149            then "adult"
    when 150..299           then "master"
    else                         "eternal"
    end
  end
end
