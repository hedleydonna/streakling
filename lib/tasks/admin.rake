namespace :admin do
  desc "Make a user an admin by email"
  task :make_admin, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rake admin:make_admin[email@example.com]"
      exit 1
    end

    user = User.find_by(email: args[:email])
    if user.nil?
      puts "User with email '#{args[:email]}' not found"
      exit 1
    end

    user.update(admin: true)
    puts "User '#{user.email}' is now an admin"
  end

  desc "Remove admin status from a user by email"
  task :remove_admin, [:email] => :environment do |t, args|
    if args[:email].blank?
      puts "Usage: rake admin:remove_admin[email@example.com]"
      exit 1
    end

    user = User.find_by(email: args[:email])
    if user.nil?
      puts "User with email '#{args[:email]}' not found"
      exit 1
    end

    user.update(admin: false)
    puts "User '#{user.email}' is no longer an admin"
  end
end
