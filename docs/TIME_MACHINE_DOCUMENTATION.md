# Time Machine - Complete Documentation

## Overview

The Time Machine is a development-only debugging tool that allows simulating different dates to test habit completion, streak logic, and creature evolution scenarios. It intercepts date-dependent operations and redirects them to use a simulated date instead of the real current date.

> **📚 For detailed TimeMachine module API reference, see:** [`TIMEMACHINE_MODULE.md`](./TIMEMACHINE_MODULE.md)

---

## Current Status

**Status**: Phase 1 - Foundation Complete ✅  
**Last Updated**: After implementing "Next 7 Days" streak increment functionality (adds 6 to streak for completed habits)

### ✅ Completed Features
- [x] Basic activation/deactivation
- [x] Session-based state management
- [x] Integration with habit completion logic
- [x] UI for turning time machine on/off
- [x] Display current simulated date
- [x] Display days since start
- [x] Display original date (start_date) on Time Machine card
- [x] Integrated Time Machine card in grid layout (beside creatures)
- [x] Minimal activation link when inactive (no space taken)
- [x] "Next Day" button to advance simulated date by 1 day
- [x] "Next 7 Days" button to advance simulated date by 7 days, increment streak by 6 for completed habits, and record completions in completion history
- [x] Automatic reset of habits/creatures to initial state on activation
- [x] Turbo Streams implementation for seamless Next Day updates (no page reload, no scroll reset)
- [x] Session persistence improvements (validation before/after updates, error handling)
- [x] Habit cards update automatically when advancing days (show incomplete state for new day)

### 🔄 Future Enhancements
- [ ] "Previous Day" button to go back in time
- [ ] Manual "Reset to New" button (reset while active without deactivating)
- [ ] Jump to specific date
- [ ] Completion history tracking and display
- [ ] Day-by-day progression testing scenarios

---

## Architecture

### Core Components

#### 1. TimeMachine Module (`lib/time_machine.rb`)
Manages simulated date state and session data through a module with class methods.

**Key Methods:**
- `active?` - Returns true if time machine is currently active
- `simulated_date` - Returns the current simulated date (or real date if inactive)
- `simulated_date=` - Sets a new simulated date
- `start_date` - Returns one day before activation date (so day count starts at 1)
- `days_since_start` - Calculates days between start and simulated date (starts at 1 on activation)
- `next_day!` - Advances the simulated date by 1 day (calls `advance_days!(1)`)
- `advance_days!(days)` - Advances the simulated date by specified number of days
- `session=` - Sets the Rails session for state persistence
- `completion_history_for_date(date)` - Retrieves completion history for a date
- `record_completion(habit_id, date, completed)` - Records completion state
- `reset` - Clears all time machine session data

> **For complete module API documentation, see:** [`TIMEMACHINE_MODULE.md`](./TIMEMACHINE_MODULE.md)

#### 2. DebugController (`app/controllers/debug_controller.rb`)
Handles time machine activation/deactivation, date navigation, and habit/creature resets.

**Actions:**
- `activate` - Resets all habits/creatures, then initializes time machine session (sets start_date to yesterday so day count starts at 1)
- `deactivate` - Clears time machine session state
- `next_day` - Advances simulated date by 1 day (uses Turbo Streams for seamless updates)
- `next_7_days` - Advances simulated date by 7 days, adds 6 to streak for completed habits, and records completions for days 2-7 in completion history (uses Turbo Streams for seamless updates)

**Security:**
- Only works in development/test environments
- Requires user to be logged in

#### 3. Session State Structure

```ruby
session[:time_machine] = {
  'active' => true/false,
  'simulated_date' => "2025-12-04",  # Current simulated date (ISO string)
  'start_date' => "2025-12-03",      # One day before activation (so day count starts at 1)
  'completion_history' => {           # Track completions by date/habit
    "2025-12-04" => {
      "habit_id_1" => true,
      "habit_id_2" => false
    },
    "2025-12-05" => {
      "habit_id_1" => true,
      "habit_id_2" => true
    }
  }
}
```

---

## Core Concept: Effective Date

The entire system is built around the concept of an **"effective date"** - the date the application treats as "today" for all operations.

```
┌─────────────────────────────────────────────────────────────┐
│                    EFFECTIVE DATE SYSTEM                     │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
        Time Machine              Time Machine
           INACTIVE                  ACTIVE
                │                           │
                ▼                           ▼
    ┌───────────────────────┐   ┌───────────────────────┐
    │  effective_date =     │   │  effective_date =     │
    │  Time.zone.today      │   │  TimeMachine.         │
    │  (Real Date)          │   │    simulated_date     │
    │                       │   │  (Simulated Date)     │
    │  Example: Dec 4, 2025 │   │  Example: Dec 10, 2025│
    └───────────────────────┘   └───────────────────────┘
```

**Key Principle**: All date-dependent operations check whether the time machine is active, then use the appropriate date (real or simulated). This allows seamless switching without modifying core business logic.

---

## Integration Points

### 1. Habit Model (`app/models/habit.rb`)

Uses `current_effective_date` to determine which date to use:

```ruby
def current_effective_date
  if defined?(TimeMachine) && TimeMachine.active?
    TimeMachine.simulated_date  # Use simulated date when active
  else
    Time.zone.today             # Use real date when inactive
  end
end

def completed_today?
  completed_on == current_effective_date  # Respects time machine
end
```

### 2. HabitsController (`app/controllers/habits_controller.rb`)

Uses effective date for completions and records in history:

```ruby
def toggle
  # Determine effective date
  effective_date = TimeMachine.active? ? 
    TimeMachine.simulated_date : 
    Time.zone.today
  
  # Mark completion with effective date
  @habit.update(completed_on: effective_date)
  
  # Update creature (uses effective date internally)
  @habit.streakling_creature.update_streak_and_mood!
  
  # Record in time machine history if active
  if TimeMachine.active?
    TimeMachine.record_completion(
      @habit.id, 
      TimeMachine.simulated_date, 
      @habit.completed_today?
    )
  end
end
```

### 3. StreaklingCreature Model (`app/models/streakling_creature.rb`)

Includes `reset_to_new!` method to reset creature to initial state:

```ruby
def reset_to_new!
  self.current_streak = 0
  self.longest_streak = 0
  self.mood = "happy"
  self.consecutive_missed_days = 0
  self.is_dead = false
  self.died_at = nil
  self.revived_count = 0
  self.stage = "egg"
  self.became_eternal_at = nil
  save!
end
```

---

## User Interface

### Dashboard Display

The Time Machine UI is split into two reusable partial files for better organization:

- **`app/views/dashboard/_time_machine_link.html.erb`** - Activation link (inactive state)
- **`app/views/dashboard/_time_machine_card.html.erb`** - Time Machine card (active state)

The main dashboard view (`app/views/dashboard/index.html.erb`) renders these partials in the appropriate locations.

**When Time Machine is Inactive:**
- Shows a small link "🕰️ Activate Time Machine" after the welcome message
- Takes minimal space - just an underlined text link
- Link appears in development environment only
- No dedicated card or space taken up in the layout

**When Time Machine is Active:**
- Small activation link disappears
- Full Time Machine card appears in the grid layout (first grid item)
- Card is integrated with creature cards in the same grid system
- Card matches creature card height (`h-[600px]`) for visual consistency
- Displays:
  - "🕰️ Time Machine" title
  - Current simulated date in abbreviated format (e.g., "Dec 04, 2025") - displayed in text-2xl size
  - "Day X since activation" counter (starts at 1)
  - Original date (start_date) - displayed below the day counter with a divider (e.g., "Dec 03, 2025")
  - "⏭️ Next Day" button (indigo) - Advances simulated date by 1 day (uses Turbo Streams for seamless updates)
  - "⏩ Next 7 Days" button (purple) - Advances simulated date by 7 days, adds 6 to the streak for habits completed on the current day, and records completions for days 2-7 in the completion history (simulates completions for the 6 skipped days)
  - "Deactivate Time Machine" button (red)
- Card appears beside creatures (1-2 creatures = Time Machine beside them; 3+ creatures = Time Machine in first slot)
- Only visible in development environment

**Grid Layout Behavior:**
- Grid shows when: user has habits OR time machine is active
- Grid uses: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` (responsive)
- Time Machine card appears as first grid item when active
- Allows easy visual comparison of time machine effects on creatures without scrolling

**Partial File Structure:**
- The activation link is rendered outside the grid (before it appears)
- The time machine card is rendered inside the grid as the first item
- Both partials handle their own visibility logic (development environment checks, active state checks)
- This separation keeps the dashboard view clean and makes the time machine UI easily maintainable

**Turbo Streams Integration:**
- Both "Next Day" and "Next 7 Days" buttons use Turbo Streams for seamless updates
- Clicking either button updates only the time machine card and habit cards via `turbo_stream.replace`
- No full page reload - only the card content refreshes with the new date
- Page scroll position is maintained - no jumping back to the top
- The time machine card has `id="time_machine_card"` for Turbo Streams targeting
- Controller responds to both HTML (redirect fallback) and turbo_stream formats
- The `next_7_days` action reuses the same turbo_stream template as `next_day` for consistency

---

## Routes

### Development/Test Only Routes (`config/routes.rb`)

```ruby
# Activation
get 'debug/activate_time_machine', to: 'debug#activate', as: :debug_activate_time_machine

# Deactivation
get 'debug/deactivate_time_machine', to: 'debug#deactivate', as: :debug_deactivate_time_machine

# Date Navigation
post 'debug/next_day', to: 'debug#next_day', as: :debug_next_day
post 'debug/next_7_days', to: 'debug#next_7_days', as: :debug_next_7_days
```

---

## Complete System Flows

### Activation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                   ACTIVATION FLOW                            │
└─────────────────────────────────────────────────────────────┘

    User on Dashboard
            │
            ▼
    ┌───────────────────────┐
    │ Sees small link:      │
    │ "🕰️ Activate..."      │
    │ (after welcome msg)   │
    └───────────────────────┘
            │
            │ [Click Link]
            ▼
    ┌───────────────────────┐
    │ DebugController       │
    │ #activate             │
    └───────────────────────┘
            │
            │ [Reset All Habits & Creatures]
            ▼
    ┌─────────────────────────────────────┐
    │ For each habit:                     │
    │   • habit.completed_on = nil        │
    │   • creature.reset_to_new!          │
    │     - stage = "egg"                 │
    │     - streak = 0                    │
    │     - mood = "happy"                │
    │     - All progress reset            │
    └─────────────────────────────────────┘
            │
            │ [Initialize Session]
            ▼
    ┌─────────────────────────────────────┐
    │ session[:time_machine] = {          │
    │   'active' => true,                 │
    │   'simulated_date' => Dec 4, 2025,  │
    │   'start_date' => Dec 3, 2025,      │
    │   'completion_history' => {}        │
    │ }                                   │
    └─────────────────────────────────────┘
            │
            │ [Assign to TimeMachine]
            ▼
    ┌───────────────────────┐
    │ TimeMachine.session = │
    │   session             │
    └───────────────────────┘
            │
            │ [Redirect to Dashboard]
            ▼
    ┌───────────────────────┐
    │ Dashboard Updates:    │
    │ • Link disappears     │
    │ • Time Machine card   │
    │   appears in grid     │
    │ • Shows:              │
    │   - Current date       │
    │   - Days since start   │
    │   - Original date       │
    │   - Next Day button     │
    │   - Next 7 Days button  │
    │   - Deactivate button   │
    │ • All habits show as  │
    │   not completed       │
    │ • All creatures in    │
    │   egg stage           │
    └───────────────────────┘
            │
            ▼
    All date operations now
    use simulated date!
```

**Key Steps:**
1. User clicks "🕰️ Activate Time Machine" link
2. All habits reset: `completed_on = nil`
3. All creatures reset to initial state (egg, 0 streak, happy mood)
4. Session initialized with simulated_date = today
5. Time Machine card appears in grid
6. App now uses simulated dates for all operations

### Next Day / Next 7 Days Flow (Turbo Streams)

```
┌─────────────────────────────────────────────────────────────┐
│       NEXT DAY / NEXT 7 DAYS FLOW (TURBO STREAMS)          │
└─────────────────────────────────────────────────────────────┘

    User in Time Machine Card
            │
            ▼
    ┌─────────────────────────────┐
    │ Sees:                       │
    │ "Current: Dec 4, 2025"      │
    │ "Day 1 since activation"    │
    │ "Original: Dec 3, 2025"     │
    │ "⏭️ Next Day" button        │
    │ "⏩ Next 7 Days" button     │
    └─────────────────────────────┘
            │
            │ [Click "Next Day" or "Next 7 Days"]
            │ (Turbo-enabled button)
            ▼
    ┌───────────────────────┐
    │ Turbo sends request   │
    │ (accepts turbo_stream)│
    └───────────────────────┘
            │
            ▼
    ┌───────────────────────┐
    │ DebugController       │
    │ #next_day             │
    │ (responds_to format)  │
    └───────────────────────┘
            │
            │ [1. Validate Session Active]
            ▼
    ┌─────────────────────────────────────┐
    │ Check: session[:time_machine]       │
    │       && session[:time_machine]     │
    │       ['active'] == true            │
    │                                     │
    │ If invalid → return bad_request     │
    └─────────────────────────────────────┘
            │
            │ [2. Set TimeMachine Session]
            ▼
    ┌─────────────────────────────────────┐
    │ TimeMachine.session = session       │
    └─────────────────────────────────────┘
            │
            │ [3. Advance Date]
            ▼
    ┌─────────────────────────────────────┐
    │ For habits completed on current day:│
    │   (Next 7 Days only)                │
    │   - Add 6 to streak                 │
    │   - Update mood to "happy"          │
    │   - Update stage                    │
    │   - Record completions for days     │
    │     2-7 in completion_history       │
    │                                     │
    │ TimeMachine.next_day! or            │
    │ TimeMachine.advance_days!(7)        │
    │   current = simulated_date          │
    │   simulated_date = current + N days │
    │                                     │
    │ Dec 4, 2025 → Dec 5, 2025 (+1 day) │
    │ OR Dec 4, 2025 → Dec 11, 2025 (+7) │
    └─────────────────────────────────────┘
            │
            │ [4. Rebuild Session Hash]
            ▼
    ┌─────────────────────────────────────┐
    │ current_data =                      │
    │   session[:time_machine].dup        │
    │ current_data['simulated_date'] =    │
    │   TimeMachine.simulated_date.to_s   │
    │ session[:time_machine] =            │
    │   current_data                      │
    │                                     │
    │ (Rebuild ensures Rails detects      │
    │  session change)                    │
    └─────────────────────────────────────┘
            │
            │ [5. Re-setup TimeMachine]
            ▼
    ┌─────────────────────────────────────┐
    │ TimeMachine.session = session       │
    └─────────────────────────────────────┘
            │
            │ [6. Verify Session Still Valid]
            ▼
    ┌─────────────────────────────────────┐
    │ Check: session[:time_machine]       │
    │       && session[:time_machine]     │
    │       ['active'] == true            │
    │                                     │
    │ If invalid → return bad_request     │
    └─────────────────────────────────────┘
            │
            │ [7. Load Habits]
            ▼
    ┌─────────────────────────────────────┐
    │ @habits = current_user.habits       │
    │   .includes(:streakling_creature)   │
    │   .order(:created_at).to_a          │
    └─────────────────────────────────────┘
            │
            │ [8. Return turbo_stream format]
            ▼
    ┌─────────────────────────────────────┐
    │ next_day.turbo_stream.erb          │
    │                                     │
    │ if session valid:                   │
    │   turbo_stream.replace              │
    │     "time_machine_card"             │
    │       ↓                             │
    │     Render updated card             │
    │                                     │
    │   for each habit:                   │
    │     turbo_stream.replace            │
    │       "habit_#{habit.id}"           │
    │         ↓                           │
    │       Render updated habit card     │
    │       (shows incomplete/white       │
    │        for new day)                 │
    └─────────────────────────────────────┘
            │
            │ [Turbo updates DOM]
            ▼
    ┌─────────────────────────────────────┐
    │ Updates:                            │
    │ • Time Machine Card:                │
    │   - Date: Dec 5, 2025 (abbreviated) │
    │   - Day counter: +1 (or +7)        │
    │   - Original date: unchanged        │
    │                                     │
    │ • All Habit Cards:                  │
    │   - Show incomplete (white)         │
    │   - Ready for new day's completion  │
    │                                     │
    │ • No page reload                    │
    │ • No scroll reset                   │
    │ • Instant update                    │
    └─────────────────────────────────────┘
```

**Key Benefits of Turbo Streams:**
- **No page reload** - Only the time machine card and habit cards update
- **No scroll reset** - Page position stays exactly where you are
- **Faster updates** - Only necessary partials are re-rendered
- **Seamless UX** - Smooth, instant feedback without interruption
- **Session safety** - Validates session before/after updates, returns `bad_request` if session is lost
- **Habit sync** - All habit cards update to show incomplete state for the new day
- **HTML fallback** - Still redirects if JavaScript is disabled

**Error Handling:**
- Session validation occurs before and after date advancement
- If session is lost, returns `head :bad_request` instead of rendering template
- Prevents time machine from disappearing if session expires
- All errors are logged for debugging

### Habit Completion Flow (Active Mode)

```
┌─────────────────────────────────────────────────────────────┐
│              HABIT COMPLETION FLOW (Active)                  │
└─────────────────────────────────────────────────────────────┘

    User Clicks Habit Toggle
            │
            ▼
    ┌───────────────────────┐
    │ HabitsController      │
    │ #toggle               │
    └───────────────────────┘
            │
            │ [Check: Is time machine active?]
            ▼
    ┌───────────────────────┐
    │ TimeMachine.active?   │
    │ → Returns: true       │
    └───────────────────────┘
            │
            │ [Use simulated date]
            ▼
    ┌─────────────────────────────────────┐
    │ effective_date =                    │
    │   TimeMachine.simulated_date        │
    │   = Dec 5, 2025                     │
    │                                     │
    │ @habit.update(                      │
    │   completed_on: Dec 5, 2025         │
    │ )                                   │
    └─────────────────────────────────────┘
            │
            │ [Update Creature]
            ▼
    ┌───────────────────────┐
    │ creature.update_      │
    │   streak_and_mood!    │
    │                       │
    │ • Checks completed_on │
    │   vs simulated_date   │
    │ • Updates streak      │
    │ • Updates mood        │
    │ • Updates stage       │
    └───────────────────────┘
            │
            │ [Record in History]
            ▼
    ┌─────────────────────────────────────┐
    │ TimeMachine.record_completion(      │
    │   habit_id,                         │
    │   Dec 5, 2025,                      │
    │   true                              │
    │ )                                   │
    │                                     │
    │ completion_history: {               │
    │   "2025-12-05" => {                 │
    │     "habit_id" => true              │
    │   }                                 │
    │ }                                   │
    └─────────────────────────────────────┘
```

### Deactivation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  DEACTIVATION FLOW                           │
└─────────────────────────────────────────────────────────────┘

    User in Time Machine Card
            │
            ▼
    ┌───────────────────────┐
    │ Sees "Deactivate"     │
    │ button (red)          │
    └───────────────────────┘
            │
            │ [Click "Deactivate"]
            ▼
    ┌───────────────────────┐
    │ DebugController       │
    │ #deactivate           │
    └───────────────────────┘
            │
            │ [Clear Session]
            ▼
    ┌─────────────────────────────────────┐
    │ session.delete(:time_machine)       │
    │                                     │
    │ TimeMachine.session = session       │
    │ (now nil)                           │
    └─────────────────────────────────────┘
            │
            │ [Redirect]
            ▼
    ┌───────────────────────┐
    │ Dashboard Updates:    │
    │ • Card disappears     │
    │ • Small link          │
    │   reappears           │
    │ • All operations      │
    │   use real dates      │
    │ • Habits/creatures    │
    │   keep their state    │
    │   (not reset)         │
    └───────────────────────┘
```

---

## Date Resolution Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│              DATE RESOLUTION DECISION TREE                   │
└─────────────────────────────────────────────────────────────┘

    Application needs a date
    (e.g., "is habit completed today?")
            │
            ▼
    ┌───────────────────────┐
    │ Check:                │
    │ TimeMachine.active?   │
    └───────────────────────┘
            │
      ┌─────┴─────┐
      │           │
     YES          NO
      │           │
      ▼           ▼
┌──────────┐  ┌──────────┐
│ Return   │  │ Return   │
│ TimeMach │  │ Time.    │
│ ine.     │  │ zone.    │
│ simulate │  │ today    │
│ d_date   │  │ (real    │
│          │  │ date)    │
└──────────┘  └──────────┘
      │           │
      │           │
      └─────┬─────┘
            │
            ▼
    ┌───────────────────────┐
    │ Use this date for:    │
    │ • Habit completion    │
    │ • Date comparisons    │
    │ • Creature updates    │
    │ • All date logic      │
    └───────────────────────┘
```

---

## Session State Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│              SESSION STATE LIFECYCLE                         │
└─────────────────────────────────────────────────────────────┘

    INITIAL STATE
    ┌───────────────────────┐
    │ session[:time_machine]│
    │ = nil                 │
    └───────────────────────┘
            │
            │ [User activates]
            ▼
    RESET PHASE
    ┌─────────────────────────────────────┐
    │ All habits: completed_on = nil      │
    │ All creatures reset to:             │
    │   - stage: "egg"                    │
    │   - streak: 0                       │
    │   - mood: "happy"                   │
    │   - All progress cleared            │
    └─────────────────────────────────────┘
            │
            ▼
    ACTIVE STATE
    ┌─────────────────────────────────────┐
    │ session[:time_machine] = {          │
    │   'active' => true,                 │
    │   'simulated_date' => "2025-12-04", │
    │   'start_date' => "2025-12-03",     │
    │   'completion_history' => {}        │
    │ }                                   │
    └─────────────────────────────────────┘
            │
            │ [User clicks "Next Day"]
            │ [Multiple times...]
            │ [User toggles habits...]
            ▼
    ADVANCED STATE
    ┌─────────────────────────────────────┐
    │ session[:time_machine] = {          │
    │   'active' => true,                 │
    │   'simulated_date' => "2025-12-10", │
    │   'start_date' => "2025-12-03",     │
    │   'completion_history' => {         │
    │     "2025-12-05" => {               │
    │       "habit_id_1" => true          │
    │     },                              │
    │     "2025-12-06" => {               │
    │       "habit_id_1" => true          │
    │     }                               │
    │   }                                 │
    │ }                                   │
    └─────────────────────────────────────┘
            │
            │ [User deactivates]
            ▼
    CLEARED STATE
    ┌───────────────────────┐
    │ session[:time_machine]│
    │ = nil                 │
    │ (deleted)             │
    │                       │
    │ Note: Habits/creatures│
    │ keep their current    │
    │ state (not reset)     │
    └───────────────────────┘
```

**Key Points:**
- Session persists across requests
- State survives page refreshes
- Reset only happens on activation (habits/creatures reset to initial state)
- Only cleared explicitly on deactivation
- All changes are stored in Rails session

---

## Example User Journey

```
DAY 1: Activation & Reset
───────────────────────────────────────────────
1. User logs in → sees dashboard
2. User has 2 habits with creatures at:
   - Habit 1: Completed yesterday, creature at "teen" stage (45 day streak)
   - Habit 2: Not completed, creature at "baby" stage (10 day streak)
3. User clicks "🕰️ Activate Time Machine" link
4. Time Machine activates:
   - All habits reset: completed_on = nil
   - All creatures reset to egg stage, 0 streak, happy mood
   - simulated_date = Dec 4, 2025
   - start_date = Dec 3, 2025 (one day before to make day count start at 1)
5. Time Machine card appears showing:
   - "Current Simulated Date" label
   - Date: "Dec 04, 2025" (abbreviated month format, text-2xl)
   - "Day 1 since activation"
   - "Original Date: Dec 03, 2025"
6. All habits now show as not completed
7. All creatures now show as eggs

DAY 2: First Completion
───────────────────────────────────────────────
1. User clicks "⏭️ Next Day" or "⏩ Next 7 Days" (Turbo Streams update - no page reload)
2. simulated_date advances: Dec 4 → Dec 5 (or Dec 4 → Dec 11 for 7 days)
3. Time Machine card updates seamlessly:
   - Date: "Dec 05, 2025" (or "Dec 11, 2025" if 7 days advanced)
   - "Day 2 since activation" (or "Day 8" if 7 days advanced)
   - Original date unchanged: "Dec 03, 2025"
   - Page position maintained, no scroll reset
4. User toggles Habit 1
5. Habit 1 marked complete for Dec 5, 2025
6. Creature updates: streak = 1, stage = "newborn"
7. Completion recorded in history

DAY 3-7: Building Streak
───────────────────────────────────────────────
1. User clicks "Next Day" each day or uses "Next 7 Days" for faster progression (instant Turbo Streams updates)
2. Each day, toggles Habit 1
3. Creature evolves:
   - Day 3: Newborn
   - Day 7: Baby (after 7 completions)
4. Completion history builds for each day
5. All updates are instant and seamless - no page reloads or scroll resets

DAY 8: Deactivation
───────────────────────────────────────────────
1. User clicks "Deactivate"
2. Session cleared
3. App returns to real date (Dec 4, 2025)
4. All operations use real time
5. Habits/creatures keep their current state
   (Habit 1: completed on Dec 5, creature at baby stage)
```

---

## Technical Decisions

1. **Session-Based Storage**: State stored in Rails session to persist across requests
   - No database impact
   - Per-user isolation
   - Easy cleanup

2. **Module Pattern**: `TimeMachine` is a module with class methods for easy access
   - No instantiation needed
   - Simple API: `TimeMachine.active?`

3. **Explicit Routing**: Routes explicitly map to controller actions to avoid naming conflicts

4. **Environment Gating**: Only available in development/test environments for safety

5. **No Global Date Override**: Instead of monkey-patching `Date.today`, we use explicit checks (`effective_date`) to avoid infinite loops

6. **Minimal Inactive UI**: When inactive, only shows small link to minimize visual clutter

7. **Grid Integration**: When active, Time Machine card integrated into same grid as creatures for easy visual comparison

8. **Automatic Reset on Activation**: When time machine activates, all habits and creatures are automatically reset to initial state to provide a clean testing environment

9. **Turbo Streams for Date Advancement**: Both "Next Day" and "Next 7 Days" buttons use Turbo Streams to update the time machine card and habit cards without a full page reload. This provides:
   - Better UX (no scroll reset, instant feedback)
   - Faster updates (only relevant partials re-render)
   - Maintains page context for easier testing scenarios
   - Both actions share the same turbo_stream template for consistency

---

## Key Files

- `app/controllers/debug_controller.rb` - Activation/deactivation/next_day/next_7_days logic with reset functionality
- `lib/time_machine.rb` - Core time machine module
- `config/routes.rb` - Time machine routes
- `app/views/dashboard/index.html.erb` - Main dashboard view (renders time machine partials)
- `app/views/dashboard/_time_machine_link.html.erb` - Time Machine activation link partial (inactive state)
- `app/views/dashboard/_time_machine_card.html.erb` - Time Machine card partial (active state) with `id="time_machine_card"`
- `app/views/debug/next_day.turbo_stream.erb` - Turbo Stream template shared by both `next_day` and `next_7_days` actions for updating time machine card
- `app/models/habit.rb` - Integration with effective date
- `app/models/streakling_creature.rb` - Reset method (`reset_to_new!`)
- `app/controllers/habits_controller.rb` - Integration with toggle logic
- `app/controllers/dashboard_controller.rb` - Sets up TimeMachine session

---

## Troubleshooting

**Time Machine not working?**
- Check you're in development/test environment
- Verify session is being set: check `session[:time_machine]` in console
- Ensure `TimeMachine.session = session` is called in controller

**Date not advancing?**
- Check session is being updated: `session[:time_machine] = session[:time_machine].dup`
- Verify `TimeMachine.next_day!` is being called
- Check browser isn't caching the old date

**Habits not using simulated date?**
- Ensure `TimeMachine.active?` returns true
- Check habit model uses `current_effective_date`
- Verify controller uses effective date for completions

**Creatures not resetting on activation?**
- Check `reset_to_new!` method exists on StreaklingCreature model
- Verify transaction completed successfully
- Check for errors in Rails logs

---

## Testing Notes

- Time machine only works when user is authenticated
- Only available in development/test environments
- Session state persists until explicitly cleared
- All date-dependent operations respect the simulated date when active
- On activation, all habits and creatures are reset to initial state
- On deactivation, habits and creatures keep their current state (not reset)

---

## Summary

The Time Machine works by:

1. **Intercepting date requests** - All date-dependent code checks if time machine is active
2. **Substituting dates** - When active, simulated date replaces real date
3. **Resetting state on activation** - All habits and creatures reset to initial state for clean testing
4. **Tracking state in session** - Session stores current simulated date and completion history
5. **Providing controls** - UI allows activation, date advancement, and deactivation
6. **Maintaining isolation** - Changes only affect the current session/user

This allows developers to test time-dependent features (streaks, creature evolution, etc.) without waiting for real time to pass, starting from a clean slate each time the time machine is activated.

---

## Related Documentation

- [`TIMEMACHINE_MODULE.md`](./TIMEMACHINE_MODULE.md) - Complete TimeMachine module API reference

