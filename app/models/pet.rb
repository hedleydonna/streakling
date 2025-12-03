class Pet < ApplicationRecord
  belongs_to :user

  # -------------------------------
  # SPECIES SYSTEM (unlocked by longest streak)
  # -------------------------------
  SPECIES = {
    heart:   { name: "Classic",        emoji: "Heart",      unlock: 0 },
    cat:     { name: "Cat",            emoji: "Cat",        unlock: 10 },
    dog:     { name: "Dog",            emoji: "Dog",        unlock: 20 },
    dragon:  { name: "Dragon",         emoji: "Dragon",     unlock: 30 },
    fox:     { name: "Fox",            emoji: "Fox",        unlock: 50 },
    panda:   { name: "Panda",          emoji: "Panda",      unlock: 75 },
    phoenix: { name: "Phoenix",        emoji: "Phoenix",    unlock: 100 },
    robot:   { name: "Robot",          emoji: "Robot",      unlock: 180 },
    unicorn: { name: "Rainbow Unicorn",emoji: "Unicorn",    unlock: 365 }
  }.freeze

  # Current species based on user's longest streak
  def current_species
    SPECIES.find { |_, data| user.longest_streak >= data[:unlock] }&.first || :heart
  end

  def emoji
    SPECIES[current_species][:emoji]
  end

  def species_name
    SPECIES[current_species][:name]
  end

  # -------------------------------
  # MOOD SYSTEM (still uses the mood column)
  # -------------------------------
  def mood
    read_attribute(:mood)&.to_sym || :happy
  end

  def dead?
    mood == :dead
  end

  # This runs every time a habit is toggled
  def update_mood!
    completed = user.habits.where("completed_on >= ?", Time.zone.today.beginning_of_day).count
    total     = user.habits.count

    new_mood = if total.zero?
                 :happy
               elsif completed == total
                 :happy
               elsif completed >= total * 0.7
                 :okay
               elsif completed >= total * 0.4
                 :sad
               elsif completed > 0
                 :sick
               else
                 :dead
               end

    # RESURRECTION LOGIC
    if new_mood != :dead && mood == :dead && user.current_streak >= 7
      update!(mood: :happy, level: level + 20)
      # This flash is read in the view to trigger confetti
      flash[:resurrected] = true
      return
    end

    update!(mood: new_mood) if mood != new_mood
  end
end
