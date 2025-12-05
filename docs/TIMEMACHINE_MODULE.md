# TimeMachine Module - Complete Reference

## Overview

The `TimeMachine` module is a Ruby module located in `lib/time_machine.rb` that manages simulated date state for the development-only time machine feature. It provides a centralized interface for controlling and querying simulated dates, tracking completion history, and managing session-based state persistence.

**Module Type**: Ruby Module with Class Methods  
**Location**: `lib/time_machine.rb`  
**Purpose**: Simulate different dates for testing habit completion, streak logic, and creature evolution

---

## Architecture

### Module Structure

```ruby
module TimeMachine
  # Session assignment method (public)
  def self.session=(session)
    # ...
  end

  class << self
    # Public API methods
    # Private helper methods
  end
end
```

The module uses a class-method-only pattern (via `class << self`) to provide a namespace for time machine functionality without requiring instantiation.

### Session Management

The TimeMachine module uses a class instance variable (`@current_session`) to store a reference to the Rails session. This allows the module to read and write session data without requiring the session to be passed to every method call.

**Session Storage Pattern:**
```
@current_session (class instance variable)
  └── session[:time_machine] (Rails session hash)
      ├── 'active' => boolean
      ├── 'simulated_date' => string (ISO date)
      ├── 'start_date' => string (ISO date)
      └── 'completion_history' => hash
```

---

## Public API Methods

### Session Management

#### `session=(session)`

**Signature**: `TimeMachine.session = session`

**Purpose**: Assigns the Rails session to the TimeMachine module, enabling all other methods to access session data.

**Parameters**:
- `session` - Rails session object (Hash-like)

**Returns**: The assigned session

**Usage Example**:
```ruby
# In a controller
TimeMachine.session = session
```

**Called From**:
- `DebugController#setup_time_machine` (before_action)
- `DashboardController#setup_time_machine` (before_action)
- `HabitsController#setup_time_machine` (before_action)
- `DebugController#activate`
- `DebugController#deactivate`

**Important Notes**:
- Must be called before any other TimeMachine methods
- Typically called in a controller `before_action`
- The session reference is stored in `@current_session` class instance variable

---

### State Query Methods

#### `active?`

**Signature**: `TimeMachine.active?` → `Boolean`

**Purpose**: Determines whether the time machine is currently active (using simulated dates).

**Returns**:
- `true` - Time machine is active, use simulated dates
- `false` - Time machine is inactive, use real dates

**Implementation**:
```ruby
def active?
  session_data && session_data['active']
end
```

**Logic Flow**:
```
active? called
    │
    ├─→ session_data exists?
    │   │
    │   ├─→ NO → return false
    │   │
    │   └─→ YES → check session_data['active']
    │              │
    │              ├─→ true → return true
    │              └─→ false/nil → return false
```

**Usage Examples**:
```ruby
# Check if time machine is active
if TimeMachine.active?
  date = TimeMachine.simulated_date
else
  date = Time.zone.today
end

# Conditional logic
effective_date = TimeMachine.active? ? 
  TimeMachine.simulated_date : 
  Time.zone.today
```

**Used In**:
- `app/models/habit.rb` - `current_effective_date` method
- `app/controllers/habits_controller.rb` - Date resolution in toggle action

---

### Date Access Methods

#### `simulated_date`

**Signature**: `TimeMachine.simulated_date` → `Date`

**Purpose**: Returns the current simulated date. Falls back to real date if time machine is inactive.

**Returns**: `Date` object representing the current simulated date (or real date if inactive)

**Implementation**:
```ruby
def simulated_date
  if session_data && session_data['simulated_date']
    Date.parse(session_data['simulated_date'])
  else
    Time.zone.today  # Fallback to real date
  end
end
```

**Behavior**:
- **When Active**: Returns parsed date from `session[:time_machine]['simulated_date']`
- **When Inactive**: Returns `Time.zone.today` (real current date)
- **Session Missing**: Returns `Time.zone.today` (safe fallback)

**Important Design Decision**:
Uses `Time.zone.today` as fallback instead of `Date.today` to avoid potential infinite loops that could occur if `Date.today` were monkey-patched to call `TimeMachine.simulated_date`.

**Usage Examples**:
```ruby
# Get current simulated date
date = TimeMachine.simulated_date
puts date.strftime("%B %d, %Y")  # "December 04, 2025"

# Use in conditional
if TimeMachine.active?
  completion_date = TimeMachine.simulated_date
end
```

**Used In**:
- `app/views/dashboard/index.html.erb` - Display current simulated date
- `app/models/habit.rb` - Get effective date when active
- `app/controllers/habits_controller.rb` - Date resolution and completion recording
- `app/controllers/debug_controller.rb` - Display and advance date

---

#### `simulated_date=(date)`

**Signature**: `TimeMachine.simulated_date = date`

**Purpose**: Sets the simulated date in the session.

**Parameters**:
- `date` - `Date` object, string, or date-like object that can be converted to string

**Returns**: The assigned date as a string (stored in session)

**Implementation**:
```ruby
def simulated_date=(date)
  ensure_session_data
  session_data['simulated_date'] = date.to_s
end
```

**Behavior**:
1. Ensures session data structure exists
2. Converts date to string format (ISO: "YYYY-MM-DD")
3. Stores in `session[:time_machine]['simulated_date']`

**Storage Format**:
- Stored as string: `"2025-12-04"`
- Automatically converted when read via `simulated_date` method

**Usage Examples**:
```ruby
# Set to specific date
TimeMachine.simulated_date = Date.parse("2025-12-10")

# Set to date object
TimeMachine.simulated_date = Date.today + 5.days

# Set to string (converted automatically)
TimeMachine.simulated_date = "2025-12-15"
```

**Used In**:
- `TimeMachine.advance_days!` - Advances date by specified number of days
- Could be used by future features (jump to date, set specific date, etc.)

---

#### `start_date`

**Signature**: `TimeMachine.start_date` → `Date`

**Purpose**: Returns the date when the time machine was activated (when the session was initialized).

**Returns**: `Date` object representing the activation start date

**Implementation**:
```ruby
def start_date
  if session_data && session_data['start_date']
    Date.parse(session_data['start_date'])
  else
    Time.zone.today  # Fallback
  end
end
```

**Behavior**:
- **When Session Exists**: Returns parsed date from `session[:time_machine]['start_date']`
- **When Session Missing**: Returns `Time.zone.today` (safe fallback)

**Use Cases**:
- Calculate how many days have passed since activation
- Track when time machine session began
- Display "Day X since activation" in UI

**Usage Examples**:
```ruby
# Get start date
activation_date = TimeMachine.start_date

# Calculate elapsed time
days_elapsed = (TimeMachine.simulated_date - TimeMachine.start_date).to_i
```

**Used In**:
- `TimeMachine.days_since_start` - Calculate days elapsed
- `app/views/dashboard/index.html.erb` - Display days since activation

---

#### `days_since_start`

**Signature**: `TimeMachine.days_since_start` → `Integer`

**Purpose**: Calculates the number of days between the start date (activation) and the current simulated date.

**Returns**: Integer representing days elapsed

**Implementation**:
```ruby
def days_since_start
  (simulated_date - start_date).to_i
end
```

**Formula**:
```
days_since_start = simulated_date - start_date
```

**Behavior**:
- Always returns a positive integer or zero
- Returns 0 on the day of activation (same day)
- Increases as simulated date advances
- Uses integer conversion to ensure whole days

**Usage Examples**:
```ruby
# Get days elapsed
days = TimeMachine.days_since_start
# => 5  (if simulated_date is 5 days after start_date)

# Display in UI
"Day #{TimeMachine.days_since_start} since activation"
```

**Used In**:
- `app/views/dashboard/index.html.erb` - Display counter in Time Machine card

**Example Scenarios**:
```
Activation: Dec 4, 2025 (start_date)
Current: Dec 4, 2025 (simulated_date)
Result: 0 days

Current: Dec 5, 2025 (after 1 "Next Day" click)
Result: 1 day

Current: Dec 10, 2025 (after 6 "Next Day" clicks)
Result: 6 days
```

---

### Date Manipulation Methods

#### `next_day!`

**Signature**: `TimeMachine.next_day!` → `Date`

**Purpose**: Advances the simulated date by exactly 1 day.

**Returns**: The new simulated date (after advancement)

**Implementation**:
```ruby
def next_day!
  advance_days!(1)
end
```

**Behavior**:
- Calls `advance_days!(1)` to advance by exactly 1 day
- See `advance_days!` method documentation for implementation details

**Important Notes**:
- Mutates session state (uses `!` naming convention)
- Requires session to be set first
- Convenience wrapper around `advance_days!(1)`
- For advancing by multiple days, use `advance_days!` directly

**Usage Examples**:
```ruby
# Advance by one day
TimeMachine.next_day!
# Dec 4, 2025 → Dec 5, 2025

# For multiple days, use advance_days! instead
TimeMachine.advance_days!(7)  # Advances 7 days
```

**Used In**:
- `app/controllers/debug_controller.rb` - `next_day` action

**See Also**: `advance_days!` - The underlying method that performs the actual date advancement

**Example Flow**:
```ruby
# Before
TimeMachine.simulated_date  # => #<Date: 2025-12-04>

# Call
TimeMachine.next_day!

# After
TimeMachine.simulated_date  # => #<Date: 2025-12-05>
```

---

#### `advance_days!`

**Signature**: `TimeMachine.advance_days!(days)` → `Date`

**Purpose**: Advances the simulated date by a specified number of days. This is the underlying method used by `next_day!` and can advance by any number of days.

**Parameters**:
- `days` (Integer) - Number of days to advance (must be positive)

**Returns**: The new simulated date after advancement

**Implementation**:
```ruby
def advance_days!(days)
  ensure_session_data
  current = simulated_date
  new_date = current + days.days
  
  # Update both the module state and the session directly
  if @current_session && @current_session[:time_machine]
    @current_session[:time_machine]['simulated_date'] = new_date.to_s
  end
end
```

**Behavior**:
1. Ensures session data structure exists
2. Gets current simulated date
3. Calculates new date: `current + days.days` using ActiveSupport's date arithmetic
4. Updates session with new date (as ISO string)
5. Automatically handles month/year boundaries

**Important Notes**:
- Mutates session state (uses `!` naming convention)
- Requires session to be set first
- Uses ActiveSupport's `days.days` for date arithmetic
- Updates session directly to ensure persistence

**Usage Examples**:
```ruby
# Advance by 7 days
TimeMachine.advance_days!(7)
# Dec 4, 2025 → Dec 11, 2025

# Advance by 1 day (same as next_day!)
TimeMachine.advance_days!(1)
# Dec 4, 2025 → Dec 5, 2025

# Advance by 30 days
TimeMachine.advance_days!(30)
# Dec 4, 2025 → Jan 3, 2026
```

**Used In**:
- `TimeMachine.next_day!` - Calls `advance_days!(1)`
- `app/controllers/debug_controller.rb` - `next_7_days` action (advances by 7 days)

**Example Flow**:
```ruby
# Before
TimeMachine.simulated_date  # => #<Date: 2025-12-04>

# Call
TimeMachine.advance_days!(7)

# After
TimeMachine.simulated_date  # => #<Date: 2025-12-11>
```

---

### Completion History Methods

#### `record_completion(habit_id, date, completed)`

**Signature**: `TimeMachine.record_completion(habit_id, date, completed)`

**Purpose**: Records whether a habit was completed or not on a specific date in the completion history.

**Parameters**:
- `habit_id` - Integer or string representing the habit's ID
- `date` - Date object representing the completion date
- `completed` - Boolean indicating completion status (`true` = completed, `false` = not completed)

**Returns**: The stored completion status

**Implementation**:
```ruby
def record_completion(habit_id, date, completed)
  ensure_session_data
  session_data['completion_history'] ||= {}
  session_data['completion_history'][date.to_s] ||= {}
  session_data['completion_history'][date.to_s][habit_id.to_s] = completed
end
```

**Data Structure Created**:
```ruby
session[:time_machine]['completion_history'] = {
  "2025-12-04" => {
    "1" => true,   # Habit #1 was completed
    "2" => false   # Habit #2 was not completed
  },
  "2025-12-05" => {
    "1" => true,
    "2" => true
  }
}
```

**Behavior**:
- Automatically creates nested hash structure if missing
- Converts `habit_id` to string for consistent storage
- Converts `date` to string (ISO format) as hash key
- Overwrites previous completion status for same habit/date combination

**Usage Examples**:
```ruby
# Record completion
TimeMachine.record_completion(1, Date.parse("2025-12-04"), true)

# Record non-completion
TimeMachine.record_completion(2, Date.parse("2025-12-04"), false)

# Record with current simulated date
TimeMachine.record_completion(
  habit.id, 
  TimeMachine.simulated_date, 
  true
)
```

**Used In**:
- `app/controllers/habits_controller.rb` - Records completion when time machine is active

**Design Notes**:
- Stores state snapshot, not a log of actions
- Only stores final state (last completion status for each habit/date)
- Used for potential future features (replay, history viewing, etc.)

---

#### `completion_history_for_date(date)`

**Signature**: `TimeMachine.completion_history_for_date(date)` → `Hash`

**Purpose**: Retrieves all completion records for a specific date from the completion history.

**Parameters**:
- `date` - Date object or date-like object representing the date to query

**Returns**: Hash mapping habit IDs (as strings) to completion status (boolean), or empty hash `{}` if no records exist

**Implementation**:
```ruby
def completion_history_for_date(date)
  session_data && 
  session_data['completion_history'] && 
  session_data['completion_history'][date.to_s] || 
  {}
end
```

**Return Format**:
```ruby
{
  "1" => true,   # Habit ID 1: completed
  "2" => false,  # Habit ID 2: not completed
  "3" => true    # Habit ID 3: completed
}
```

**Behavior**:
- Returns empty hash `{}` if:
  - Session data doesn't exist
  - Completion history doesn't exist
  - No records exist for the specified date
- Converts date to string for lookup
- Safe: never returns `nil`, always returns a hash

**Usage Examples**:
```ruby
# Get history for specific date
history = TimeMachine.completion_history_for_date(Date.parse("2025-12-04"))
# => {"1" => true, "2" => false}

# Check if habit was completed
history = TimeMachine.completion_history_for_date(Date.today)
if history["1"] == true
  puts "Habit 1 was completed today"
end

# Iterate over completions
TimeMachine.completion_history_for_date(date).each do |habit_id, completed|
  puts "Habit #{habit_id}: #{completed ? 'completed' : 'not completed'}"
end
```

**Used In**:
- Currently not used in codebase (infrastructure for future features)

**Potential Future Uses**:
- Display completion history for a date
- Replay completions for a specific day
- Build completion calendar view
- Analyze completion patterns

---

### State Management Methods

#### `reset`

**Signature**: `TimeMachine.reset`

**Purpose**: Clears all time machine session data, resetting the time machine to an inactive state.

**Returns**: `nil`

**Implementation**:
```ruby
def reset
  session_data.clear if session_data
end
```

**Behavior**:
- Clears the entire `session[:time_machine]` hash if it exists
- Safe: checks if `session_data` exists before clearing
- Does not delete the hash key, just clears its contents
- After reset, `active?` will return `false`

**Usage Examples**:
```ruby
# Reset time machine state
TimeMachine.reset

# Reset and verify
TimeMachine.reset
TimeMachine.active?  # => false
```

**Used In**:
- Currently not used in codebase (available for future features)

**Note**: This is different from deactivation. `reset` clears session data but doesn't handle the controller redirect logic that `DebugController#deactivate` provides.

---

## Private Helper Methods

### `session_data` (private)

**Signature**: `session_data` → `Hash` or `nil`

**Purpose**: Returns the time machine session hash, or `nil` if session is not set.

**Returns**:
- `Hash` - The `session[:time_machine]` hash if session exists
- `nil` - If session is not set or time machine hash doesn't exist

**Implementation**:
```ruby
private

def session_data
  @current_session && @current_session[:time_machine]
end
```

**Access Pattern**:
```
@current_session (class instance variable)
  └── session[:time_machine] (Rails session hash)
```

**Used By**: All public methods that need to read/write session data

---

### `ensure_session_data` (private)

**Signature**: `ensure_session_data`

**Purpose**: Ensures the time machine session hash exists, creating it if necessary.

**Returns**: `nil` (creates side effect of initializing hash)

**Implementation**:
```ruby
private

def ensure_session_data
  @current_session[:time_machine] ||= {} if @current_session
end
```

**Behavior**:
- Only creates hash if `@current_session` exists
- Creates empty hash `{}` if `session[:time_machine]` doesn't exist
- Safe: doesn't overwrite existing hash

**Used By**: Methods that write to session (`simulated_date=`, `record_completion`, `next_day!`)

**Example**:
```ruby
# Before: session[:time_machine] doesn't exist
ensure_session_data
# After: session[:time_machine] = {}
```

---

## Session Data Structure

### Complete Structure

```ruby
session[:time_machine] = {
  'active' => true,                    # Boolean: Is time machine active?
  'simulated_date' => "2025-12-04",   # String: Current simulated date (ISO format)
  'start_date' => "2025-12-04",       # String: Date when activated (ISO format)
  'completion_history' => {            # Hash: Completion records by date
    "2025-12-04" => {                 # Date key (string, ISO format)
      "1" => true,                    # Habit ID (string) => completion status (boolean)
      "2" => false
    },
    "2025-12-05" => {
      "1" => true,
      "2" => true
    }
  }
}
```

### Field Descriptions

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `active` | Boolean | Indicates if time machine is active | `true` |
| `simulated_date` | String | Current simulated date (ISO format) | `"2025-12-04"` |
| `start_date` | String | Date when time machine was activated | `"2025-12-04"` |
| `completion_history` | Hash | Nested hash: date → habit_id → status | See structure above |

### Initialization

The session structure is initialized in `DebugController#activate`:

```ruby
session[:time_machine] = {
  'active' => true,
  'simulated_date' => Time.zone.today.to_s,
  'start_date' => Time.zone.today.to_s,
  'completion_history' => {}
}
```

---

## Usage Patterns

### Pattern 1: Date Resolution

The most common pattern is checking if time machine is active and using the appropriate date:

```ruby
def current_effective_date
  if TimeMachine.active?
    TimeMachine.simulated_date
  else
    Time.zone.today
  end
end
```

**Used In**:
- `app/models/habit.rb` - `current_effective_date` method
- `app/controllers/habits_controller.rb` - Date resolution

---

### Pattern 2: Session Setup

Controllers that use TimeMachine must set the session:

```ruby
class SomeController < ApplicationController
  before_action :setup_time_machine

  private

  def setup_time_machine
    TimeMachine.session = session
  end
end
```

**Used In**:
- `DebugController`
- `DashboardController`
- `HabitsController`

---

### Pattern 3: Conditional Recording

Record completions only when time machine is active:

```ruby
if TimeMachine.active?
  completed = habit.completed_today?
  TimeMachine.record_completion(
    habit.id, 
    TimeMachine.simulated_date, 
    completed
  )
end
```

**Used In**:
- `app/controllers/habits_controller.rb` - Toggle action

---

### Pattern 4: Date Advancement

Advance simulated date and update UI:

```ruby
def next_day
  TimeMachine.next_day!
  session[:time_machine] = session[:time_machine].dup  # Force session update
  redirect_to root_path, notice: "Advanced to #{TimeMachine.simulated_date}"
end
```

**Used In**:
- `app/controllers/debug_controller.rb` - Next day action

---

## Design Decisions

### 1. Why Module with Class Methods?

**Decision**: Use module with `class << self` pattern instead of a class

**Rationale**:
- No need for instantiation - time machine is a singleton concept
- Class methods are simpler to call: `TimeMachine.active?` vs `TimeMachine.instance.active?`
- Fits Rails convention for utility modules
- Easier to test and mock

**Alternative Considered**: Singleton class pattern - rejected for complexity

---

### 2. Why Session Storage Instead of Database?

**Decision**: Store state in Rails session, not database

**Rationale**:
- Per-user isolation (each developer has own session)
- No database migrations needed
- Easy cleanup (clear session = reset state)
- Temporary/debugging tool doesn't need persistence
- Rails native mechanism

**Trade-offs**:
- Session cleared on browser close (may be desired for debug tool)
- Limited by session size (not a concern for this use case)

---

### 3. Why Explicit Checks Instead of Monkey-Patching?

**Decision**: Use explicit `TimeMachine.active?` checks instead of overriding `Date.today`

**Rationale**:
- Avoid infinite loops (if `Date.today` calls `TimeMachine.simulated_date` which calls `Date.today`)
- More transparent - code shows where time machine is used
- Easier to debug
- More maintainable

**Alternative Considered**: Global `Date.today` override - rejected due to complexity and risks

---

### 4. Why String Storage for Dates?

**Decision**: Store dates as strings in session, parse when reading

**Rationale**:
- Sessions serialize to JSON/YAML - Date objects need conversion anyway
- String format (ISO: "YYYY-MM-DD") is human-readable
- Consistent format regardless of timezone
- Easy to debug by inspecting session

**Trade-offs**:
- Need to parse on read (minimal performance cost)
- Must remember to convert (handled internally by methods)

---

### 5. Why Fallback to Real Date?

**Decision**: Methods like `simulated_date` return real date when inactive

**Rationale**:
- Methods always return valid dates (no nil checks needed)
- Graceful degradation - app works normally when time machine off
- Simplifies calling code

**Example**:
```ruby
# Always safe to call
date = TimeMachine.simulated_date  # Returns real date if inactive
```

---

## Error Handling

The TimeMachine module is designed to be resilient and fail gracefully:

### Safe Fallbacks

- `simulated_date` → Falls back to `Time.zone.today` if session missing
- `start_date` → Falls back to `Time.zone.today` if session missing
- `active?` → Returns `false` if session missing (inactive state)
- `completion_history_for_date` → Returns `{}` if no data exists

### No Exceptions

The module is designed to never raise exceptions in normal usage:
- All methods handle missing session gracefully
- All methods handle missing data structures gracefully
- Empty hashes returned instead of nil to avoid nil errors

### Session Requirements

Some methods require session to be set first:
- Writing methods (`simulated_date=`, `record_completion`, `next_day!`) will create empty hash if needed
- Reading methods work without session (return fallbacks)

---

## Testing Considerations

### What to Mock

When testing code that uses TimeMachine:

```ruby
# Mock active state
allow(TimeMachine).to receive(:active?).and_return(true)

# Mock simulated date
allow(TimeMachine).to receive(:simulated_date).and_return(Date.parse("2025-12-10"))

# Mock session
TimeMachine.session = {}
```

### Session Testing

To test with actual session:

```ruby
# Set up session
session[:time_machine] = {
  'active' => true,
  'simulated_date' => '2025-12-04'
}
TimeMachine.session = session

# Test methods
expect(TimeMachine.active?).to be true
expect(TimeMachine.simulated_date).to eq(Date.parse("2025-12-04"))
```

---

## Dependencies

### ActiveSupport

The module relies on ActiveSupport for date arithmetic:

```ruby
current + 1.day  # ActiveSupport extension
```

This requires:
- ActiveSupport to be loaded (automatic in Rails)
- Time zone awareness (`Time.zone.today`)

### Rails Session

The module requires:
- Rails session object (Hash-like interface)
- Session to support nested hashes
- Session persistence mechanism (cookie-based or other)

---

## Future Enhancement Possibilities

### Potential Additions

1. **`previous_day!`** - Go back in time
   ```ruby
   def previous_day!
     ensure_session_data
     current = simulated_date
     self.simulated_date = current - 1.day
   end
   ```

2. **`jump_to_date(date)`** - Set specific date
   ```ruby
   def jump_to_date(date)
     ensure_session_data
     self.simulated_date = date
   end
   ```

3. **`reset_to_start!`** - Reset to activation date
   ```ruby
   def reset_to_start!
     ensure_session_data
     self.simulated_date = start_date
   end
   ```

4. **`completion_history`** - Get all history
   ```ruby
   def completion_history
     session_data && session_data['completion_history'] || {}
   end
   ```

5. **`clear_completion_history!`** - Clear history
   ```ruby
   def clear_completion_history!
     ensure_session_data
     session_data['completion_history'] = {}
   end
   ```

---

## Summary

The `TimeMachine` module provides:

- **Session-based state management** for simulated dates
- **Simple API** with class methods (no instantiation needed)
- **Safe fallbacks** for graceful degradation
- **Completion tracking** for potential future features
- **Date manipulation** (advance time)
- **Query methods** (check status, get dates)

It's designed to be:
- **Simple to use** - Clear method names, consistent patterns
- **Safe** - Graceful fallbacks, no exceptions
- **Flexible** - Easy to extend with new features
- **Well-integrated** - Works seamlessly with Rails session

For integration examples and system-wide flow, see:
- [`TIME_MACHINE_HOW_IT_WORKS.md`](./TIME_MACHINE_HOW_IT_WORKS.md) - Complete system documentation
- [`NEW_TIME_MACHINE_SPEC.md`](./NEW_TIME_MACHINE_SPEC.md) - Implementation summary

