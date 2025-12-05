module TimeMachine
  def self.session=(session)
    @current_session = session
  end

  class << self
    def active?
      session_data && session_data['active']
    end

    def simulated_date
      if session_data && session_data['simulated_date']
        Date.parse(session_data['simulated_date'])
      else
        # Use Time.zone.today to avoid infinite loop with Date.today override
        Time.zone.today
      end
    end

    def simulated_date=(date)
      ensure_session_data
      session_data['simulated_date'] = date.to_s
    end

    def start_date
      if session_data && session_data['start_date']
        Date.parse(session_data['start_date'])
      else
        # Use Time.zone.today to avoid infinite loop with Date.today override
        Time.zone.today
      end
    end

    def completion_history_for_date(date)
      session_data && session_data['completion_history'] && session_data['completion_history'][date.to_s] || {}
    end

    def record_completion(habit_id, date, completed)
      ensure_session_data
      session_data['completion_history'] ||= {}
      session_data['completion_history'][date.to_s] ||= {}
      session_data['completion_history'][date.to_s][habit_id.to_s] = completed
    end

    def days_since_start
      (simulated_date - start_date).to_i
    end

    def reset
      session_data.clear if session_data
    end

    private

    def session_data
      @current_session && @current_session[:time_machine]
    end

    def ensure_session_data
      @current_session[:time_machine] ||= {} if @current_session
    end
  end
end
