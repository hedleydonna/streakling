class StreaklingCreature < ApplicationRecord
  belongs_to :habit

  validates :habit_id, uniqueness: true

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
    STAGES.find { |_, data| effective_streak.between?(data[:min], data[:max]) }&.first || :egg
  end

  def stage_name
    STAGES[current_stage][:name] || "Egg"
  end

  def message
    # Special messages for Eternal creatures
    if eternal?
      if habit.completed_today?
        eternal_completion_message
      else
        eternal_missed_message
      end
    # Special messages for dead creatures
    elsif is_dead?
      case days_since_death
      when 1..3
        "They've moved on to a better place... but you can bring them back with 7 straight days of consistency."
      when 4..6
        "The tombstone stands as a reminder of what was lost, but hope remains."
      when 7..
        "✨ A spark of life! Complete this habit today to begin the revival process. ✨"
      else
        "Rest in peace... but you can revive them with 7 consecutive completions."
      end
    elsif !habit.completed_today?
      # Show missed day message when habit was not completed
      missed_day_message
    else
      STAGES[current_stage][:message] || "I’m waiting for you…"
    end
  end

  def missed_day_message
    case consecutive_missed_days
    when 1
      "I missed you today... but I know you'll be back tomorrow! 💙"
    when 2
      "Two days without you... I'm starting to worry. Please come back soon. 😟"
    when 3
      "It's been three days... I feel like something's missing. Where are you? 🥺"
    when 4
      "Four days now... I'm really concerned about you. Let's get back on track! 😢"
    when 5
      "Five days... I'm not feeling well. Your consistency means everything to me. 🤒"
    when 6
      "Six days of silence... I'm getting weaker. I need your help! 😷"
    when 7
      "A week without you... I'm fading. Please, let's rebuild our bond. 💔"
    when 8
      "Eight days... the world feels colder without your presence. I miss you. ❄️"
    when 9
      "Nine days now... I'm barely holding on. Your return would mean everything. 🌧️"
    when 10
      "Ten days... I'm so weak. Please remember our journey together. 🏥"
    when 11..15
      "The days blur together... #{consecutive_missed_days} without you. I need you back. ⏳"
    when 16..20
      "I'm fading away... #{consecutive_missed_days} days without your light. Please return. 🌑"
    when 21
      "Today marks 21 days... I can't hold on anymore. This is goodbye... 💀"
    else
      "The silence continues... #{consecutive_missed_days} days and counting. I miss you. 😔"
    end
  end

  def emoji
    # Dead creatures show tombstone
    return "🪦" if is_dead?

    base = ANIMAL_TYPES[animal_type&.to_sym]&.dig(:emoji) || "🐉"

    case current_stage
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

  def mood_emoji
    case mood&.to_sym
    when :happy then "😊"
    when :okay  then "😐"
    when :sad   then "😢"
    when :sick  then "🤒"
    when :dead  then "💀"
    else "😊"
    end
  end

  def stage_emoji
    case current_stage
    when :egg     then "🥚"
    when :newborn then "✨"
    when :baby    then "👶"
    when :child   then "👦"
    when :teen    then "🧑"
    when :adult   then "👨"
    when :master  then "👑"
    when :eternal then "🌈"
    else "🥚"
    end
  end

  def eternal?
    current_streak >= 300
  end

  def days_since_death
    return 0 unless is_dead? && died_at
    (Time.zone.today - died_at).to_i
  end

  def revive!
    self.is_dead = false
    self.died_at = nil
    self.current_streak = 7  # Start as baby
    self.consecutive_missed_days = 0
      self.mood = "happy"
    self.stage = "baby"
    self.revived_count += 1

    # Could add fireworks animation/notification here
    puts "🎆 Creature revived with fireworks! 🎆"
  end

  def eternal_completion_message
    # Check for anniversary (yearly celebration)
    if reached_eternal_on_anniversary?
      "🎉 HAPPY ANNIVERSARY! #{eternal_years} years ago today, we achieved eternity together! Our bond grows stronger every day. 🌟"
    else
      [
        "Together forever! Our eternal bond shines brighter with each day. ✨",
        "Eternal love knows no bounds. Thank you for being my forever companion. 💫",
        "In the grand tapestry of time, our journey together is eternal. 🌈",
        "You raised a legend, and now we walk through eternity side by side. 👑",
        "Our story transcends time itself. Forever yours, eternally grateful. 💎"
      ].sample
                  end
    end
  
  def eternal_missed_message
    [
      "Even eternal beings need their rest... but I still appreciate you! 🌙",
      "Our eternal bond remains unbroken, even on challenging days. 💪",
      "Time may pass, but our connection is forever. Tomorrow brings new adventures! 🌅",
      "Eternal patience is one of my greatest strengths. I know you'll be back. 🕊️",
      "Legends are forged through all experiences. Our journey continues! ⚔️"
    ].sample
  end

  def reached_eternal_on_anniversary?
    return false unless became_eternal_at

    today = Time.zone.today
    became_eternal_day = became_eternal_at.day
    became_eternal_month = became_eternal_at.month

    today.day == became_eternal_day && today.month == became_eternal_month
  end

  def eternal_years
    return 0 unless became_eternal_at

    ((Time.zone.today - became_eternal_at) / 365.25).floor
  end

  def update_streak_and_mood!
    if habit.completed_today?
      # They completed it today → streak continues or starts
      self.current_streak += 1
      self.longest_streak = [longest_streak, current_streak].max
      self.consecutive_missed_days = 0

      # Check for revival: 7 consecutive completions while dead
      if is_dead? && current_streak >= 7
        revive!
        return # Don't set mood/stage again after revival
      end

      self.mood = "happy"
    else
      # Missed today - only mood changes for first 4 misses
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

      # Stage regression starts at day 5
      # Don't reset current_streak to 0 anymore - preserve progress
      # Instead, handle stage regression in the stage calculation
    end

    # Update stage based on effective streak (accounting for regression)
    self.stage = effective_stage_key

    # Track when creature first becomes Eternal
    if eternal? && became_eternal_at.nil?
      self.became_eternal_at = Time.zone.today
    end

    save!
  end

  def effective_streak
    # Eternal creatures don't regress
    return current_streak if eternal?

    return current_streak if consecutive_missed_days <= 4

    # Calculate regression penalty: lose 1 stage every 2 missed days starting at day 5
    regression_days = consecutive_missed_days - 4
    stages_to_lose = (regression_days / 2.0).ceil

    # Get current stage based on actual streak
    current_stage_index = stage_index_for_streak(current_streak)

    # Apply regression, but never drop below baby stage (index 2)
    regressed_stage_index = [current_stage_index - stages_to_lose, 2].max

    # Convert back to minimum streak for that stage
    streak_for_stage_index(regressed_stage_index)
  end

  private

  def effective_stage_key
    case effective_streak
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

  def stage_index_for_streak(streak)
    case streak
    when 0                  then 0  # egg
    when 1..6               then 1  # newborn
    when 7..21              then 2  # baby
    when 22..44             then 3  # child
    when 45..79             then 4  # teen
    when 80..149            then 5  # adult
    when 150..299           then 6  # master
    else                         7  # eternal
    end
  end

  def streak_for_stage_index(index)
    case index
    when 0 then 0    # egg
    when 1 then 1    # newborn
    when 2 then 7    # baby
    when 3 then 22   # child
    when 4 then 45   # teen
    when 5 then 80   # adult
    when 6 then 150  # master
    when 7 then 300  # eternal
    else 0
    end
  end

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
