# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed Stages from current STAGES constant data
# This populates the stages table with all stage definitions
stages_data = [
  { key: 'egg', name: 'Egg', min_streak: 0, max_streak: 0, default_message: "I'm waiting for you…", emoji: '🥚', display_order: 0 },
  { key: 'newborn', name: 'Newborn', min_streak: 1, max_streak: 6, default_message: "I hatched because of you!", emoji: '👶', display_order: 1 },
  { key: 'baby', name: 'Baby', min_streak: 7, max_streak: 21, default_message: "I'm learning to walk with you", emoji: '🧒', display_order: 2 },
  { key: 'child', name: 'Child', min_streak: 22, max_streak: 44, default_message: "We're growing up together!", emoji: '👦', display_order: 3 },
  { key: 'teen', name: 'Teen', min_streak: 45, max_streak: 79, default_message: "Look how strong we've become", emoji: '🧑', display_order: 4 },
  { key: 'adult', name: 'Adult', min_streak: 80, max_streak: 149, default_message: "You did it — I'm who I am because of you", emoji: '👤', display_order: 5 },
  { key: 'master', name: 'Master', min_streak: 150, max_streak: 299, default_message: "We are unstoppable", emoji: '🌟', display_order: 6 },
  { key: 'eternal', name: 'Eternal', min_streak: 300, max_streak: 9999, default_message: "You raised a legend. I love you forever.", emoji: '✨', display_order: 7 }
]

stages_data.each do |stage_data|
  Stage.find_or_create_by!(key: stage_data[:key]) do |stage|
    stage.assign_attributes(stage_data)
  end
end

puts "Seeded #{Stage.count} stages"

# Seed Creature Types from current ANIMAL_TYPES constant data
# NOTE: This section will be uncommented when the creature_types table is created
# (Part of the creature_types table migration - see MASTER_PLAN.md)
#
# creature_types_data = [
#   { key: 'dragon', name: 'Dragon', emoji: '🐉', description: 'A majestic dragon', display_order: 0 },
#   { key: 'phoenix', name: 'Phoenix', emoji: '🦅', description: 'A fiery phoenix', display_order: 1 },
#   { key: 'fox', name: 'Fox', emoji: '🦊', description: 'A clever fox', display_order: 2 },
#   { key: 'lion', name: 'Lion', emoji: '🦁', description: 'A regal lion', display_order: 3 },
#   { key: 'unicorn', name: 'Unicorn', emoji: '🦄', description: 'A magical unicorn', display_order: 4 },
#   { key: 'panda', name: 'Panda', emoji: '🐼', description: 'A cuddly panda', display_order: 5 },
#   { key: 'owl', name: 'Owl', emoji: '🦉', description: 'A wise owl', display_order: 6 }
# ]
#
# creature_types_data.each do |type_data|
#   CreatureType.find_or_create_by!(key: type_data[:key]) do |type|
#     type.assign_attributes(type_data)
#   end
# end
#
# puts "Seeded #{CreatureType.count} creature types"
