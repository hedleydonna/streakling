# Time Machine Rebuild - Implementation Summary

## Overview

This document summarizes the rebuild of the Time Machine feature from scratch. The Time Machine is a development-only debugging tool that allows simulating different dates to test habit completion, streak logic, and creature evolution scenarios.

## Current Status: Phase 1 - Foundation Complete ✅

### What We Built

1. **Minimal Starting Point**
   - Removed all previous time machine code and UI elements
   - Started with just a title ("🕰️ Time Machine") and a single activation button
   - Clean slate for incremental feature addition

2. **Activation System**
   - Simple button to turn the time machine on
   - Creates session-based state management
   - App switches from real dates to simulated dates when active

3. **Deactivation System**
   - Button to turn the time machine off
   - Returns app to normal real-time operation
   - Cleans up session data

---

## Architecture

### Core Components

#### 1. **TimeMachine Module** (`lib/time_machine.rb`)
- **Purpose**: Manages simulated date state and session data
- **Key Methods**:
  - `active?` - Returns true if time machine is currently active
  - `simulated_date` - Returns the current simulated date (or real date if inactive)
  - `simulated_date=` - Sets a new simulated date
  - `start_date` - Returns the date when time machine was activated
  - `days_since_start` - Calculates days between start and simulated date
  - `session=` - Sets the Rails session for state persistence
  - `completion_history_for_date(date)` - Retrieves completion history for a date
  - `record_completion(habit_id, date, completed)` - Records completion state
  - `reset` - Clears all time machine session data

#### 2. **DebugController** (`app/controllers/debug_controller.rb`)
- **Purpose**: Handles time machine activation/deactivation
- **Actions**:
  - `activate` - Initializes time machine session state
  - `deactivate` - Clears time machine session state
- **Security**: Only works in development/test environments
- **Authentication**: Requires user to be logged in

#### 3. **Session State Structure**
```ruby
session[:time_machine] = {
  'active' => true/false,
  'simulated_date' => "2025-12-04",  # Current simulated date
  'start_date' => "2025-12-04",      # When time machine was activated
  'completion_history' => {           # Track completions by date/habit
    "2025-12-04" => {
      "habit_id_1" => true,
      "habit_id_2" => false
    }
  }
}
```

---

## Integration Points

### 1. **Habit Model** (`app/models/habit.rb`)
- **Method**: `current_effective_date`
  - Returns `TimeMachine.simulated_date` if time machine is active
  - Returns `Time.zone.today` if time machine is inactive
- **Method**: `completed_today?`
  - Uses `current_effective_date` to check completion
  - Respects simulated dates when time machine is active

### 2. **HabitsController** (`app/controllers/habits_controller.rb`)
- **Toggle Action**:
  - Uses `effective_date` (simulated or real) when marking habits complete
  - Records completions in time machine history if active

---

## User Interface

### Dashboard Display (`app/views/dashboard/index.html.erb`)

**When Time Machine is Inactive:**
- Shows "🕰️ Time Machine" title
- Shows "Activate Time Machine" button (purple)
- Only visible in development environment

**When Time Machine is Active:**
- Shows "🕰️ Time Machine" title
- Shows "Deactivate Time Machine" button (red)
- Only visible in development environment

---

## Routes

### Development/Test Only Routes (`config/routes.rb`)
```ruby
# Activation
get 'debug/activate_time_machine', to: 'debug#activate', as: :debug_activate_time_machine

# Deactivation
get 'debug/deactivate_time_machine', to: 'debug#deactivate', as: :debug_deactivate_time_machine
```

---

## How It Works

### Activation Flow
1. User clicks "Activate Time Machine" button
2. `DebugController#activate` is called
3. Session hash is initialized with:
   - `active: true`
   - `simulated_date: Time.zone.today` (starts at current real date)
   - `start_date: Time.zone.today`
   - `completion_history: {}`
4. Session is assigned to `TimeMachine` module
5. User redirected to dashboard with success message
6. App now uses simulated dates for all date-dependent operations

### Deactivation Flow
1. User clicks "Deactivate Time Machine" button
2. `DebugController#deactivate` is called
3. Session hash is deleted (`session.delete(:time_machine)`)
4. `TimeMachine.session` is cleared
5. User redirected to dashboard with success message
6. App returns to using real dates (`Time.zone.today`)

### Effective Date Concept
Throughout the app, the concept of "effective date" is used:
- **When Time Machine is OFF**: `effective_date = Time.zone.today` (real date)
- **When Time Machine is ON**: `effective_date = TimeMachine.simulated_date` (simulated date)

This allows the app to seamlessly switch between real and simulated time without changing the core logic.

---

## Current Limitations & Future Work

### ✅ Completed
- [x] Basic activation/deactivation
- [x] Session-based state management
- [x] Integration with habit completion logic
- [x] UI for turning time machine on/off

### 🔄 Next Steps (Not Yet Implemented)
- [ ] Display current simulated date
- [ ] Display days since start
- [ ] "Next Day" button to advance simulated date
- [ ] "Previous Day" button to go back in time
- [ ] "Reset to New" button to reset all habits to initial state
- [ ] Visual indicators showing time machine is active
- [ ] Day-by-day progression testing
- [ ] Completion history tracking and display

---

## Technical Decisions

1. **Session-Based Storage**: State stored in Rails session to persist across requests
2. **Module Pattern**: `TimeMachine` is a module with class methods for easy access
3. **Explicit Routing**: Routes explicitly map to controller actions to avoid naming conflicts
4. **Environment Gating**: Only available in development/test environments
5. **No Global Date Override**: Instead of monkey-patching `Date.today`, we use explicit checks (`effective_date`) to avoid infinite loops

---

## Key Files Modified

- `app/controllers/debug_controller.rb` - Activation/deactivation logic
- `lib/time_machine.rb` - Core time machine module
- `config/routes.rb` - Time machine routes
- `app/views/dashboard/index.html.erb` - UI display
- `app/models/habit.rb` - Integration with effective date
- `app/controllers/habits_controller.rb` - Integration with toggle logic

---

## Testing Notes

- Time machine only works when user is authenticated
- Only available in development/test environments
- Session state persists until explicitly cleared
- All date-dependent operations respect the simulated date when active

