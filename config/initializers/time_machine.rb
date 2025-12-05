# Time Machine initializer - DISABLED to avoid infinite loops
# We'll handle date simulation at the model/controller level instead
# Rails.application.config.to_prepare do
#   Date.class_eval do
#     class << self
#       alias_method :real_today, :today
#
#       def today
#         if defined?(TimeMachine) && TimeMachine.active?
#           TimeMachine.simulated_date
#         else
#           real_today
#         end
#       end
#     end
#   end
# end
