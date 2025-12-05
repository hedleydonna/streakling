# StreaklingCreature Model - Complete Documentation

## Overview

The `StreaklingCreature` model represents the virtual pet/companion that grows and evolves based on the user's habit completion consistency. Each creature is associated with exactly one habit, and its state (stage, mood, streak, health) reflects how consistently the user completes that habit.

> **Key Concept**: The creature's lifecycle is a reflection of the user's consistency. Complete habits regularly, and your creature thrives. Miss too many days, and your creature regresses, gets sick, and can even die—but can be revived with 7 consecutive completions.

---

## Database Schema

### Table: `streakling_creatures`

```ruby
create_table "streakling_creatures" do |t|
  t.bigint "habit_id", null: false                    # Foreign key to habits table
  t.string "streakling_name", default: "Little One"   # User-given name
  t.string "animal_type", default: "dragon"           # Type: dragon, phoenix, fox, etc.
  t.integer "current_streak", default: 0              # Current consecutive completions
  t.integer "longest_streak", default: 0              # Best streak ever achieved
  t.string "mood", default: "happy"                   # Current emotional state
  t.integer "consecutive_missed_days", default: 0     # Days missed in a row
  t.boolean "is_dead", default: false                 # Death status flag
  t.date "died_at"                                    # Date of death (if dead)
  t.integer "revived_count", default: 0               # Times creature has been revived
  t.string "stage", default: "egg"                    # Current growth stage
  t.date "became_eternal_at"                          # Date when Eternal status achieved
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end
```

### Relationships

- **belongs_to :habit** - Each creature belongs to exactly one habit
- **delegate :user** - Access user through `creature.habit.user`
- **delegate :completed_today?** - Check if associated habit is completed today

---

## Core Concepts

### 1. Stages (Growth Levels)

Creatures progress through 8 distinct stages based on their effective streak:

| Stage | Streak Range | Name | Emoji | Description |
|-------|--------------|------|-------|-------------|
| **Egg** | 0 | Egg | 🥚 | Initial state - waiting to hatch |
| **Newborn** | 1-6 | Newborn | ✨🐉 | Just hatched! |
| **Baby** | 7-21 | Baby | 👶🐉 | Learning and growing |
| **Child** | 22-44 | Child | 🐉 | Active and playful |
| **Teen** | 45-79 | Teen | 🐉 | Strong and independent |
| **Adult** | 80-149 | Adult | 🐉 | Fully matured |
| **Master** | 150-299 | Master | 👑🐉 | Peak performance |
| **Eternal** | 300+ | Eternal | 🌈🐉 | Legendary status - no regression |

**Important**: Stage is calculated using `effective_streak`, which accounts for regression penalties.

### 2. Moods (Emotional States)

Creatures have 5 mood states that reflect their recent care:

| Mood | Emoji | Trigger | Behavior |
|------|-------|---------|----------|
| **happy** | 😊 | Habit completed today | Default positive state |
| **okay** | 😐 | 1 missed day | Slightly concerned |
| **sad** | 😢 | 2-4 missed days | Worried and lonely |
| **sick** | 🤒 | 5-20 missed days | Weakening, stage regression begins |
| **dead** | 💀 | 21+ consecutive missed days | Creature has died |

**Mood Progression Flow**:
```
Completed → happy
Miss 1 day → okay
Miss 2-4 days → sad
Miss 5-20 days → sick (regression begins)
Miss 21+ days → dead
```

### 3. Streaks

Two types of streaks are tracked:

- **`current_streak`**: Number of consecutive days the habit has been completed (resets to 0 on death, but preserved during regression)
- **`longest_streak`**: Highest streak ever achieved (never decreases, only increases)

**Key Behavior**: `current_streak` is preserved during regression (not reset to 0), but the `effective_streak` is reduced to reflect visual stage regression.

### 4. Regression System

When a creature misses 5+ consecutive days, it begins to regress in stages:

- **Days 1-4 missed**: No stage regression, only mood changes
- **Day 5+ missed**: Stage regression begins
  - Loses 1 stage every 2 missed days
  - **Minimum floor**: Never regresses below "Baby" stage (streak 7)
  - **Eternal creatures**: No regression (stay at Eternal regardless of misses)

**Example Regression**:
```
Creature at Adult stage (streak 80):
- Miss 5-6 days: Regresses to Teen (streak 45)
- Miss 7-8 days: Regresses to Child (streak 22)
- Miss 9-10 days: Regresses to Baby (streak 7) ← stops here
- Miss 11-20 days: Stays at Baby (still regressing internally)
- Miss 21+ days: Dies
```

### 5. Death and Revival

**Death Conditions**:
- Creature dies after **21 consecutive missed days**
- `is_dead` = true
- `died_at` = date of death
- `mood` = "dead"
- Shows tombstone emoji (🪦) instead of creature

**Revival Process**:
- Complete the habit **7 consecutive days** while dead
- Automatically revives at "Baby" stage (streak 7)
- `revived_count` increments
- Returns to "happy" mood

**Special Revival Messages**:
- Days 1-3: "They've moved on to a better place..."
- Days 4-6: "The tombstone stands as a reminder..."
- Day 7+: "✨ A spark of life! Complete this habit today..."

### 6. Eternal Status

**Achievement**: Reach streak of 300+

**Special Properties**:
- **No regression**: Eternal creatures never regress, even if you miss days
- **No death**: Cannot die from missed days (stays eternal)
- **Special messages**: Unique completion and missed day messages
- **Anniversary tracking**: Celebrates yearly anniversary of becoming Eternal
- **`became_eternal_at`**: Tracks the date Eternal status was first achieved

**Eternal Messages**:
- **On completion**: Rotating positive messages about eternal bond
- **On anniversary**: Special "Happy Anniversary" message with years count
- **On missed day**: Reassuring messages that eternal bond remains

---

## Key Methods and Flow

### Primary Update Method: `update_streak_and_mood!`

This is the **core method** called whenever a habit is toggled (completed or uncompleted).

```ruby
def update_streak_and_mood!
  if habit.completed_today?
    # COMPLETION PATH
  else
    # MISSED DAY PATH
  end
  # Update stage and save
end
```

#### Flowchart: `update_streak_and_mood!`

```
┌─────────────────────────────────────────────────────────┐
│          update_streak_and_mood! Called                  │
│          (Triggered by habit toggle)                     │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  habit.completed_today?       │
        └───────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
      YES                      NO
        │                       │
        ▼                       ▼
┌──────────────┐      ┌──────────────────────┐
│ COMPLETION   │      │ MISSED DAY PATH      │
│ PATH         │      │                      │
└──────────────┘      └──────────────────────┘
        │                       │
        ▼                       ▼
┌──────────────────┐  ┌─────────────────────────────┐
│ current_streak++ │  │ consecutive_missed_days++   │
│ longest_streak   │  │                             │
│   = max of both  │  │                             │
│ consecutive_     │  │ MOOD PROGRESSION:           │
│   missed_days=0  │  │ • Day 1 → "okay"            │
└──────────────────┘  │ • Days 2-4 → "sad"          │
        │             │ • Days 5-20 → "sick"        │
        ▼             │ • Day 21+ → "dead"          │
┌──────────────────┐  │   (is_dead=true,            │
│ Check for        │  │    died_at=today)           │
│ revival?         │  └─────────────────────────────┘
│ (if dead &&      │             │
│  streak >= 7)    │             │
└──────────────────┘             │
        │                        │
        ▼                        │
┌──────────────────┐             │
│ If revived:      │             │
│ • revive!        │             │
│ • return early   │             │
└──────────────────┘             │
        │                        │
        └────────┬───────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │ Set mood = "happy"     │
        │ (completion only)      │
        └────────────────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │ Calculate effective_   │
        │   stage_key            │
        │ (accounts for          │
        │  regression)           │
        └────────────────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │ Update stage field     │
        └────────────────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │ Track Eternal status   │
        │ (if streak >= 300 &&   │
        │  became_eternal_at     │
        │  is nil)               │
        └────────────────────────┘
                 │
                 ▼
        ┌────────────────────────┐
        │ save!                  │
        └────────────────────────┘
```

### Effective Streak Calculation: `effective_streak`

This method calculates the "visual" streak that determines stage display, accounting for regression penalties.

```ruby
def effective_streak
  # Eternal creatures don't regress
  return current_streak if eternal?
  
  # No regression for first 4 missed days
  return current_streak if consecutive_missed_days <= 4
  
  # Calculate regression: lose 1 stage every 2 missed days
  regression_days = consecutive_missed_days - 4
  stages_to_lose = (regression_days / 2.0).ceil
  
  # Apply regression, never below Baby stage (index 2)
  # ... (detailed calculation)
end
```

**Key Rules**:
1. **Eternal creatures**: Always return `current_streak` (no regression)
2. **First 4 misses**: Return `current_streak` (no visual change)
3. **Day 5+**: Calculate stage regression
4. **Minimum**: Never below Baby stage (effective streak 7)

**Example**:
```
Creature with current_streak = 80 (Adult stage)
Missed 10 consecutive days:

regression_days = 10 - 4 = 6
stages_to_lose = (6 / 2.0).ceil = 3 stages

Adult (index 5) - 3 = Child (index 2)
→ Returns effective_streak = 22 (Child stage minimum)
```

### Stage Determination: `current_stage` vs `effective_stage_key`

**Two stage calculation methods**:

1. **`current_stage`** (public): Uses `effective_streak` (accounts for regression)
   ```ruby
   def current_stage
     STAGES.find { |_, data| effective_streak.between?(data[:min], data[:max]) }&.first || :egg
   end
   ```

2. **`effective_stage_key`** (private): Used to set the `stage` database field
   ```ruby
   def effective_stage_key
     case effective_streak
     when 0 then "egg"
     when 1..6 then "newborn"
     # ... etc
     end
   end
   ```

**Why Both?**
- `current_stage` is the "source of truth" for display (always calculates from current state)
- `stage` field is stored in database for quick queries/reporting
- Both should always match after `update_streak_and_mood!` runs

---

## Complete Lifecycle Flow

### Scenario 1: Perfect Consistency (Egg → Eternal)

```
Day 0:  Egg (streak 0)          - "I'm waiting for you..."
Day 1:  Newborn (streak 1)      - "I hatched because of you!"
Day 7:  Baby (streak 7)         - "I'm learning to walk with you"
Day 22: Child (streak 22)       - "We're growing up together!"
Day 45: Teen (streak 45)        - "Look how strong we've become"
Day 80: Adult (streak 80)       - "You did it — I'm who I am because of you"
Day 150: Master (streak 150)    - "We are unstoppable"
Day 300: Eternal (streak 300+)  - "You raised a legend. I love you forever."
```

### Scenario 2: Regression and Recovery

```
Day 1-80:  Perfect consistency → Adult (streak 80)
Day 81:    Miss → mood: okay (streak 80, stage: Adult)
Day 82:    Miss → mood: sad (streak 80, stage: Adult) 
Day 83:    Miss → mood: sad (streak 80, stage: Adult)
Day 84:    Miss → mood: sad (streak 80, stage: Adult)
Day 85:    Miss → mood: sick (streak 80, effective_streak: 45, stage: Teen) ← REGRESSION BEGINS
Day 87:    Miss → mood: sick (streak 80, effective_streak: 22, stage: Child)
Day 89:    Miss → mood: sick (streak 80, effective_streak: 7, stage: Baby) ← FLOOR REACHED
Day 91:    Miss → mood: sick (streak 80, effective_streak: 7, stage: Baby)
...
Day 101:   Miss → mood: dead (streak 80, is_dead: true, died_at: today)
Day 102-107: Complete 6 days → streak: 6 (still dead)
Day 108:   Complete → streak: 7 → REVIVED!
           • is_dead: false
           • current_streak: 7 (reset)
           • stage: baby
           • mood: happy
```

### Scenario 3: Death and Revival

```
Day 1-50:   Perfect consistency → Child stage
Day 51-71:  Miss 21 consecutive days
Day 72:     DIES
           • is_dead: true
           • died_at: Day 72
           • mood: "dead"
           • Emoji: 🪦

Days 73-79: Complete habit (streak 1-7 building)
Day 80:     Complete → streak = 7 → REVIVES!
           • revive! method called
           • is_dead: false
           • died_at: nil
           • current_streak: 7
           • stage: "baby"
           • mood: "happy"
           • revived_count: 1
```

### Scenario 4: Eternal Creature Behavior

```
Day 1-300: Perfect consistency → Eternal status achieved
           • became_eternal_at: Day 300
           • streak: 300

Day 301-320: Miss 20 consecutive days
           • consecutive_missed_days: 20
           • mood: "sick" (but can't die)
           • effective_streak: 300 (NO REGRESSION)
           • stage: "eternal" (stays eternal)
           • Message: "Even eternal beings need their rest..."

Day 321: Complete → mood: "happy" immediately
         • Returns to normal eternal messages
         • No penalty, no regression
```

---

## Helper Methods

### Display Methods

#### `emoji`
Returns the visual emoji representation:
- Dead: 🪦 (always)
- Egg: 🥚
- Newborn: ✨ + base emoji
- Baby: 👶 + base emoji
- Child-Adult: base emoji only
- Master: 👑 + base emoji
- Eternal: 🌈 + base emoji

#### `stage_emoji`
Returns stage-specific emoji:
- Egg: 🥚
- Newborn: ✨
- Baby: 👶
- Child: 👦
- Teen: 🧑
- Adult: 👨
- Master: 👑
- Eternal: 🌈

#### `mood_emoji`
Returns mood-specific emoji:
- happy: 😊
- okay: 😐
- sad: 😢
- sick: 🤒
- dead: 💀

### Message Methods

#### `message`
Returns the appropriate message based on creature state:

**Priority Order**:
1. **Eternal + completed today** → `eternal_completion_message`
2. **Eternal + missed today** → `eternal_missed_message`
3. **Dead** → Special revival messages based on `days_since_death`
4. **Missed today (not dead)** → `missed_day_message`
5. **Completed today (normal)** → Stage-specific message from `STAGES`

#### `missed_day_message`
Returns escalating concern messages based on `consecutive_missed_days`:
- Day 1: "I missed you today..."
- Day 2: "Two days without you..."
- Days 3-4: Increasing concern
- Days 5-10: Worry and weakening
- Days 11-20: Critical condition
- Day 21: Death message
- Day 22+: Post-death messages

### Status Check Methods

#### `eternal?`
Returns `true` if `current_streak >= 300`

#### `days_since_death`
Calculates days since death: `(Time.zone.today - died_at).to_i`

#### `reached_eternal_on_anniversary?`
Checks if today is the anniversary of becoming Eternal (same day/month, any year)

#### `eternal_years`
Calculates years since becoming Eternal: `((Time.zone.today - became_eternal_at) / 365.25).floor`

### Reset Methods

#### `reset_to_new!`
Completely resets creature to initial state:
- `current_streak = 0`
- `longest_streak = 0`
- `mood = "happy"`
- `consecutive_missed_days = 0`
- `is_dead = false`
- `died_at = nil`
- `revived_count = 0`
- `stage = "egg"`
- `became_eternal_at = nil`

**Used by**: Time Machine activation, testing scenarios

#### `revive!`
Resets creature after death:
- `is_dead = false`
- `died_at = nil`
- `current_streak = 7` (starts as Baby)
- `consecutive_missed_days = 0`
- `mood = "happy"`
- `stage = "baby"`
- `revived_count++`

**Triggered automatically** when dead creature reaches streak of 7.

---

## Integration Points

### Habit Controller Integration

The creature is updated in `HabitsController#toggle`:

```ruby
def toggle
  # Update habit completion status
  if @habit.completed_today?
    @habit.update(completed_on: nil)
  else
    effective_date = TimeMachine.active? ? TimeMachine.simulated_date : Time.zone.today
    @habit.update(completed_on: effective_date)
  end

  # THIS IS THE MAGIC LINE
  @habit.streakling_creature.update_streak_and_mood!
  
  # ... respond with turbo_stream or redirect
end
```

**Flow**:
1. User toggles habit completion
2. Habit `completed_on` field updated
3. Creature's `update_streak_and_mood!` called
4. Creature state recalculated and saved
5. UI updates via Turbo Streams

### Time Machine Integration

When Time Machine is active:
- Uses `TimeMachine.simulated_date` instead of `Time.zone.today`
- `completed_today?` checks against simulated date
- Allows testing different scenarios without waiting for real time

---

## Constants

### ANIMAL_TYPES

```ruby
ANIMAL_TYPES = {
  dragon:  { name: "Dragon",  emoji: "🐉" },
  phoenix: { name: "Phoenix", emoji: "🦅" },
  fox:     { name: "Fox",     emoji: "🦊" },
  lion:    { name: "Lion",    emoji: "🦁" },
  unicorn: { name: "Unicorn", emoji: "🦄" },
  panda:   { name: "Panda",   emoji: "🐼" },
  owl:     { name: "Owl",     emoji: "🦉" }
}
```

### STAGES

```ruby
STAGES = {
  egg:      { min: 0,   max: 0,   name: "Egg",      message: "I'm waiting for you…" },
  newborn:  { min: 1,   max: 6,   name: "Newborn",  message: "I hatched because of you!" },
  baby:     { min: 7,   max: 21,  name: "Baby",     message: "I'm learning to walk with you" },
  child:    { min: 22,  max: 44,  name: "Child",    message: "We're growing up together!" },
  teen:     { min: 45,  max: 79,  name: "Teen",     message: "Look how strong we've become" },
  adult:    { min: 80,  max: 149, name: "Adult",    message: "You did it — I'm who I am because of you" },
  master:   { min: 150, max: 299, name: "Master",   message: "We are unstoppable" },
  eternal:  { min: 300, max: 9999,name: "Eternal",  message: "You raised a legend. I love you forever." }
}
```

---

## Common Patterns and Edge Cases

### Pattern 1: Streak Preservation During Regression

**Behavior**: `current_streak` is NOT reset during regression, only `effective_streak` changes.

**Why?**: Preserves user's actual progress. If they get back on track, they can recover faster.

**Example**:
```
Day 1-50: Perfect → streak: 50 (Child stage)
Day 51-60: Miss 10 days → streak: 50, effective_streak: 7 (Baby stage)
Day 61: Complete → streak: 51, effective_streak: 51 → back to Child stage instantly!
```

### Pattern 2: Minimum Stage Floor

**Behavior**: Regression never goes below Baby stage (streak 7).

**Why?**: Prevents creatures from going back to Egg/Newborn, which would feel too harsh.

### Pattern 3: Eternal Protection

**Behavior**: Eternal creatures cannot regress or die from missed days.

**Why?**: Once you achieve Eternal status, it's a permanent achievement. You've proven long-term consistency.

### Edge Case: Revival While Not Dead

**Behavior**: `revive!` should only be called when `is_dead == true`.

**Safeguard**: Revival check only happens in completion path when `is_dead? && current_streak >= 7`.

### Edge Case: Multiple Deaths

**Behavior**: Each death increments `revived_count`, but creature always revives at Baby stage.

**Design**: No cumulative penalty for multiple deaths—fresh start each revival.

---

## Testing Scenarios

### Scenario A: First Time User
1. Create habit → Creature created as Egg (streak 0)
2. Complete Day 1 → Newborn (streak 1)
3. Complete Days 2-7 → Baby (streak 7)

### Scenario B: Perfect 100-Day Streak
1. Complete 100 consecutive days
2. Final state: Adult (streak 100)
3. `longest_streak = 100`
4. Never missed, so `consecutive_missed_days = 0`

### Scenario C: Regression Recovery
1. Build to Adult (streak 80)
2. Miss 10 days (days 5-10 cause regression)
3. Effective stage: Baby (streak 7)
4. Complete 1 day → Instant recovery to Child (streak 81)
5. Because `current_streak` was preserved at 80, completing makes it 81.

### Scenario D: Death and Revival
1. Miss 21 consecutive days → Dies
2. Complete 7 consecutive days while dead
3. Day 7 completion triggers `revive!`
4. New state: Baby (streak 7), happy mood, alive

### Scenario E: Eternal Achievement
1. Complete 300 consecutive days
2. Day 300: Becomes Eternal
3. `became_eternal_at` set to today
4. Miss 50 days: Still Eternal (no regression)
5. Complete again: Returns to happy, still Eternal

---

## Summary

The StreaklingCreature model implements a complex lifecycle system that:

1. **Rewards consistency** through stage progression (Egg → Eternal)
2. **Penalizes inconsistency** through mood changes and regression (but preserves streak)
3. **Prevents permanent loss** through revival system (7 days to recover from death)
4. **Rewards long-term achievement** through Eternal status (permanent protection)
5. **Provides emotional feedback** through dynamic messages based on state

The system is designed to balance challenge with encouragement, ensuring users can always recover from mistakes while rewarding sustained consistency.

---

**Last Updated**: Initial documentation creation
