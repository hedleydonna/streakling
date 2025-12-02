json.extract! habit, :id, :name, :emoji, :user_id, :created_at, :updated_at
json.url habit_url(habit, format: :json)
