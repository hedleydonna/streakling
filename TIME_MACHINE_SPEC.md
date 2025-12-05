# 🕰️ Time Machine Technical Specification

## Overview

The Time Machine is a development/debug tool that allows developers and testers to simulate the passage of time within the Streakland application. It enables interactive, day-by-day exploration of creature evolution, habit completion, and the full lifecycle of streakling creatures.

---

## Core Concept

**Problem**: Testing creature evolution normally requires waiting days or weeks to see stage changes, mood shifts, regression, death, and revival.

**Solution**: A "simulated date" system that overrides the current date for all habit/creature logic, allowing instant day-by-day progression through time.

---

## System Architecture

```
┌─────────────────────────────────────────┐
│         USER INTERACTION                │
│  (Dashboard with Time Machine UI)       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│      TIME MACHINE SESSION STATE         │
│  ┌─────────────────────────────────┐   │
│  │ session[:time_machine] = {      │   │
│  │   active: true                  │   │
│  │   simulated_date: "2024-12-05"  │   │
│  │   start_date: "2024-12-04"      │   │
│  │   completion_history: {}        │   │
│  │ }                                │   │
│  └─────────────────────────────────┘   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│      DATE OVERRIDE SYSTEM               │
│  ┌─────────────────────────────────┐   │
│  │ Habit.completed_today?          │   │
│  │   → checks TimeMachine.active?  │   │
│  │   → uses simulated_date if yes  │   │
│  │   → uses Time.zone.today if no  │   │
│  └─────────────────────────────────┘   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│      CREATURE UPDATE LOGIC              │
│  (Unchanged - works with any date)      │
└─────────────────────────────────────────┘
```

---

## User Flow: Perfect Streak Scenario

```
┌──────────────────────────────────────────────────────────────┐
│                    START: Reset to New                       │
├──────────────────────────────────────────────────────────────┤
│  1. User clicks "🔄 Reset to New"                           │
│  2. All habits: completed_on = nil                          │
│  3. All creatures reset:                                     │
│     - current_streak = 0                                     │
│     - mood = "happy"                                         │
│     - stage = "egg"                                          │
│     - consecutive_missed_days = 0                            │
│  4. Time machine activated:                                  │
│     - simulated_date = Today                                 │
│     - start_date = Today                                     │
│     - Days Since Start = 0                                   │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│                    DAY 1: First Completion                   │
├──────────────────────────────────────────────────────────────┤
│  1. Display shows: "Current Date: Dec 4, 2024"               │
│  2. Display shows: "Days Since Start: 0"                     │
│  3. Habit toggle button shows: ○ (not completed)             │
│  4. User clicks toggle → Habit completed                     │
│     - habit.completed_on = Dec 4, 2024                       │
│     - Creature updates:                                      │
│       • current_streak = 1                                   │
│       • mood = "happy"                                       │
│       • stage = "newborn"                                    │
│  5. Toggle button now shows: ✓ (completed)                   │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              DAY 2: Advance to Next Day                      │
├──────────────────────────────────────────────────────────────┤
│  1. User clicks "⏭️ Next Day"                               │
│  2. simulated_date = Dec 5, 2024                             │
│  3. Days Since Start = 1                                     │
│  4. Habit toggle button shows: ○ (not completed for Dec 5)   │
│     - Because habit.completed_on (Dec 4) ≠ simulated_date    │
│  5. User clicks toggle → Habit completed                     │
│     - habit.completed_on = Dec 5, 2024                       │
│     - Creature updates:                                      │
│       • current_streak = 2                                   │
│       • stage = "newborn" (still)                            │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              DAY 7: Milestone Reached                        │
├──────────────────────────────────────────────────────────────┤
│  1. After 7 consecutive completions...                       │
│  2. User clicks toggle → Habit completed                     │
│  3. Creature updates:                                        │
│     - current_streak = 7                                     │
│     - stage = "baby" ⬆️ EVOLUTION!                          │
│     - Creature emoji changes: 👶🐉                          │
│     - Message: "I'm learning to walk with you"               │
└──────────────────────────────────────────────────────────────┘
```

---

## User Flow: Missed Days Scenario

```
┌──────────────────────────────────────────────────────────────┐
│              DAY 5: After 4 Perfect Days                     │
├──────────────────────────────────────────────────────────────┤
│  - Creature: Baby stage, streak = 25                         │
│  - User clicks "⏭️ Next Day"                                │
│  - simulated_date advances                                   │
│  - Habit shows: ○ (not completed)                            │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              DAY 6: First Miss                               │
├──────────────────────────────────────────────────────────────┤
│  1. User does NOT click toggle                              │
│  2. User clicks "⏭️ Next Day"                               │
│  3. Creature.update_streak_and_mood! runs automatically      │
│     (or manually triggered)                                  │
│  4. Creature updates:                                        │
│     - consecutive_missed_days = 1                            │
│     - mood = "okay" 😐                                       │
│     - stage = "child" (no change - first 4 only affect mood) │
│  5. Message changes: "I missed you today..."                │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              DAY 9: Day 5 of Missing                         │
├──────────────────────────────────────────────────────────────┤
│  1. After 5 consecutive misses...                            │
│  2. Creature updates:                                        │
│     - consecutive_missed_days = 5                            │
│     - mood = "sick" 🤒                                       │
│     - REGRESSION STARTS:                                     │
│       • effective_streak calculated                          │
│       • Lose 1 stage every 2 missed days                     │
│       • Stage: "child" → "baby" (regressed)                  │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              DAY 25: Death Occurs                            │
├──────────────────────────────────────────────────────────────┤
│  1. After 21 consecutive misses...                           │
│  2. Creature updates:                                        │
│     - consecutive_missed_days = 21                           │
│     - mood = "dead" 💀                                       │
│     - is_dead = true                                         │
│     - died_at = simulated_date                               │
│     - Emoji: 🪦 (tombstone)                                  │
│  3. Message: "They've moved on to a better place..."        │
└──────────────────────────────────────────────────────────────┘
```

---

## Key Components Breakdown

### 1. Session State Management

**Storage Location**: Rails session hash
**Structure**:
```
session[:time_machine] = {
  'active' => boolean,           # Is time machine currently active?
  'simulated_date' => string,    # Current simulated date (ISO format)
  'start_date' => string,        # When time machine was activated
  'completion_history' => hash   # Optional: track completion per date
}
```

**Lifecycle**:
- **Created**: When user clicks "Reset to New"
- **Updated**: When user clicks "Next Day" or "Previous Day"
- **Destroyed**: When user clicks "Exit Time Machine"

---

### 2. Date Override Logic

**Flow Chart**:
```
┌─────────────────────────┐
│  Habit.completed_today? │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────┐
    │ TimeMachine   │
    │ .active?      │
    └───┬───────┬───┘
        │       │
    YES │       │ NO
        │       │
        ▼       ▼
┌──────────────┐  ┌──────────────┐
│ simulated_   │  │ Time.zone.   │
│ date from    │  │ today        │
│ session      │  │ (real date)  │
└──────────────┘  └──────────────┘
        │               │
        └───────┬───────┘
                │
                ▼
    ┌─────────────────────┐
    │ Compare with        │
    │ habit.completed_on  │
    └─────────────────────┘
                │
                ▼
    ┌─────────────────────┐
    │ Return true/false   │
    └─────────────────────┘
```

---

### 3. Day Navigation System

**Next Day Flow**:
```
┌──────────────────────┐
│ User clicks          │
│ "⏭️ Next Day"       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Check: Is time       │
│ machine active?      │
└───┬──────────────┬───┘
    │              │
 YES│              │NO
    │              │
    ▼              ▼
┌─────────┐  ┌──────────────┐
│ Get     │  │ Redirect:    │
│ current │  │ Error msg    │
│ date    │  │              │
└────┬────┘  └──────────────┘
     │
     ▼
┌──────────────────────┐
│ Add 1 day to         │
│ simulated_date       │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│ Update session:      │
│ session[:time_       │
│ machine][            │
│ 'simulated_date']    │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│ Redirect to          │
│ dashboard            │
│ (page reloads)       │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│ View reads new       │
│ simulated_date       │
│ from session         │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│ Habit.completed_     │
│ today? checks new    │
│ simulated_date       │
└──────────────────────┘
     │
     ▼
┌──────────────────────┐
│ Toggle buttons       │
│ show correct state   │
│ (○ or ✓)            │
└──────────────────────┘
```

---

### 4. Habit Toggle Behavior

**When Time Machine is Active**:
```
┌──────────────────────┐
│ User clicks toggle   │
│ button               │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Check: Is habit      │
│ completed_today?     │
│ (uses simulated_date)│
└───┬──────────────┬───┘
    │              │
 YES│              │NO
    │              │
    ▼              ▼
┌─────────┐  ┌──────────────┐
│ Set     │  │ Set          │
│ completed_│  │ completed_  │
│ on = nil│  │ on =         │
│         │  │ simulated_   │
│         │  │ date         │
└────┬────┘  └──────┬───────┘
     │              │
     └──────┬───────┘
            │
            ▼
┌──────────────────────┐
│ Update creature:     │
│ streak, mood, stage  │
└────┬─────────────────┘
     │
     ▼
┌──────────────────────┐
│ Refresh UI via       │
│ Turbo Stream         │
└──────────────────────┘
```

---

## State Transitions

### Time Machine States

```
┌──────────────┐
│   INACTIVE   │
│              │
│ No simulated │
│ date override│
└──────┬───────┘
       │
       │ User clicks
       │ "Reset to New"
       ▼
┌──────────────┐
│    ACTIVE    │
│              │
│ simulated_   │
│ date = today │
│ days = 0     │
└───┬──────┬───┘
    │      │
    │      │ User clicks
    │      │ "Next Day"
    │      │ repeatedly
    │      │
    │      ▼
    │ ┌──────────────┐
    │ │  ADVANCING   │
    │ │              │
    │ │ simulated_   │
    │ │ date moves   │
    │ │ forward      │
    │ │ days > 0     │
    │ └──────┬───────┘
    │        │
    │        │ User clicks
    │        │ "Previous Day"
    │        ▼
    │ ┌──────────────┐
    │ │  REWINDING   │
    │ │              │
    │ │ simulated_   │
    │ │ date moves   │
    │ │ backward     │
    │ │ (but never   │
    │ │  < start)    │
    │ └──────┬───────┘
    │        │
    │        └──────┐
    │               │
    │ User clicks   │
    │ "Exit"        │
    │               │
    └───────────────┘
            │
            ▼
    ┌──────────────┐
    │   INACTIVE   │
    │              │
    │ Back to      │
    │ real time    │
    └──────────────┘
```

---

## Data Flow: Complete Picture

```
┌──────────────────────────────────────────────────────────────┐
│                      USER ACTIONS                            │
│  • Reset to New                                              │
│  • Toggle Habit                                              │
│  • Next Day / Previous Day                                   │
│  • Exit Time Machine                                         │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│                  DEBUG CONTROLLER                            │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Actions:                                           │     │
│  │  • reset_to_new → Initialize session               │     │
│  │  • next_day → Update simulated_date +1             │     │
│  │  • previous_day → Update simulated_date -1         │     │
│  │  • exit_time_machine → Clear session               │     │
│  └───────────────────┬────────────────────────────────┘     │
└──────────────────────┼───────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────┐
│              RAILS SESSION STORAGE                            │
│  session[:time_machine] = {                                  │
│    active: true,                                             │
│    simulated_date: "2024-12-05",                             │
│    start_date: "2024-12-04"                                  │
│  }                                                            │
└──────────────┬───────────────────────────────────────────────┘
               │
               ├─────────────────────────┐
               │                         │
               ▼                         ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│    HABIT MODEL           │  │  STREAKLING CREATURE     │
│                          │  │  MODEL                   │
│  completed_today?        │  │                          │
│    ↓                     │  │  update_streak_and_mood! │
│  Check TimeMachine       │  │    ↓                     │
│  .active?                │  │  Checks habit.completed_ │
│    ↓                     │  │  today? (uses simulated) │
│  Return: simulated_date  │  │    ↓                     │
│  or real date            │  │  Updates streak, mood,   │
│                          │  │  stage based on date     │
└──────────────────────────┘  └──────────────────────────┘
               │                         │
               └─────────────┬───────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │      DASHBOARD VIEW      │
              │                          │
              │  • Reads session for     │
              │    time machine status   │
              │  • Calls habit.          │
              │    completed_today?      │
              │  • Shows toggle buttons  │
              │    with correct state    │
              │  • Displays creature     │
              │    with current stats    │
              └──────────────────────────┘
```

---

## Critical Behaviors

### 1. Date Consistency

**Rule**: When time machine is active, ALL date checks must use simulated_date, not real date.

**Affected Operations**:
- ✅ Habit completion checking (`completed_today?`)
- ✅ Habit toggle (setting `completed_on`)
- ✅ Creature update calculations
- ✅ Creature message generation (checks completion status)

### 2. Session Persistence

**Rule**: Time machine state must persist across page reloads and requests.

**Implementation**:
- Store in Rails session (survives redirects)
- Update session explicitly on each navigation action
- View reads from session directly (not from TimeMachine module)

### 3. Date Navigation Boundaries

**Rule**: Cannot go before the start_date when using Previous Day.

**Logic**:
```
if new_date >= start_date
  ✅ Allow navigation
else
  ❌ Show error: "Cannot go before starting date"
end
```

### 4. Habit State Per Date

**Rule**: Each simulated date has its own completion state.

**Example**:
- Day 1 (Dec 4): Habit completed → `completed_on = Dec 4`
- Day 2 (Dec 5): Habit NOT completed → `completed_on ≠ Dec 5`
- Toggle button shows: ○ (not completed for current simulated date)

---

## Expected User Experience

### Perfect Streak Test (Day 1-365)

1. **Reset to New**: All habits fresh, creatures at Egg stage
2. **Day 1**: Toggle habit → Creature becomes Newborn
3. **Day 2-7**: Continue toggling → Creature evolves to Baby
4. **Day 8-22**: Continue → Creature becomes Child, then Teen
5. **Day 80+**: Creature becomes Adult
6. **Day 150+**: Creature becomes Master
7. **Day 300+**: Creature becomes Eternal (no regression possible)

### Missed Days Test (Regression)

1. **Reset to New**: Start fresh
2. **Day 1-4**: Complete habits → Creature grows
3. **Day 5-8**: DON'T toggle → Watch mood change (OK → Sad)
4. **Day 9+**: Continue missing → Watch stage regression begin
5. **Day 25+**: After 21 misses → Creature dies (tombstone)
6. **Day 26-32**: Complete 7 days in a row → Creature revives!

---

## Current Issues to Address

### Issue 1: Date Not Applied to Habits
**Problem**: When advancing days, habits don't recognize the new simulated date
**Root Cause**: TBD - need to verify date override is working in all places

### Issue 2: Session Persistence
**Problem**: Time machine state may be lost between requests
**Root Cause**: Session updates not being saved properly

### Issue 3: Creature Updates on Date Change
**Problem**: Creatures may not update when date advances without completing habits
**Root Cause**: Creature updates only happen on habit toggle, not on date change

---

## Design Decisions

### Why Session-Based?
- ✅ Persists across page reloads
- ✅ User-specific (each user has own time machine)
- ✅ Easy to clear (exit time machine)

### Why Not Database?
- ❌ Would affect all users
- ❌ Harder to reset
- ❌ Overhead for debug tool

### Why Simulated Date, Not Time Travel?
- ✅ Simpler - just override date checks
- ✅ No need to modify existing records
- ✅ Can exit and return to real time instantly

---

## Testing Scenarios

### Scenario 1: Single Habit, Perfect Streak
- Reset → Complete Day 1 → Next Day → Complete Day 2 → ... → Day 300 (Eternal)

### Scenario 2: Multiple Habits, Mixed Completion
- Reset → Complete Habit A on Day 1 → Complete Habit B on Day 2 → Watch both creatures evolve differently

### Scenario 3: Regression and Recovery
- Reset → Complete 10 days → Miss 5 days → Watch regression → Complete 7 days → Watch revival

### Scenario 4: Date Navigation
- Reset → Advance to Day 10 → Go back to Day 5 → Verify habits show correct completion state for Day 5

---

## Future Enhancements (Not Implemented)

- **Timeline View**: Visual calendar showing completion history
- **Jump to Date**: Quick navigation to specific dates
- **Save/Restore States**: Save time machine state for later
- **Bulk Date Operations**: "Fast forward 30 days" with auto-completion logic
- **Comparison Mode**: Side-by-side view of different completion patterns

