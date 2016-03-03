begin
  require "pry"
rescue LoadError
end

%w(
  ask
  panic
  queue
  scoreboard
).each { |mod| require_relative "./handlers/#{mod}" }

Lita.configure do |config|
  # The name your robot will use.
  config.robot.name = "DC Bot"

  # The locale code for the language to use.
  # config.robot.locale = :en

  # The severity of messages to log. Options are:
  # :debug, :info, :warn, :error, :fatal
  # Messages at the selected level and above will be logged.
  config.robot.log_level = :info

  # An array of user IDs that are considered administrators. These users
  # the ability to add and remove other users from authorization groups.
  # What is considered a user ID will change depending on which adapter you use.
  # config.robot.admins = ["1", "2"]

  # The adapter you want to connect with. Make sure you've added the
  # appropriate gem to the Gemfile.
  config.robot.adapter        = :slack
  config.adapters.slack.token = ENV.fetch("SLACK_TOKEN")
  config.robot.admins         = ENV.fetch("ADMINS").split(",")
  config.redis[:url]          = ENV.fetch("REDISTOGO_URL")
  config.http.port            = ENV.fetch("PORT", 3999)

  ## Example: Set options for the chosen adapter.
  # config.adapter.username = "myname"
  # config.adapter.password = "secret"

  ## Example: Set options for the Redis connection.
  # config.redis.host = "127.0.0.1"
  # config.redis.port = 1234

  ## Example: Set configuration for any loaded handlers. See the handler's
  ## documentation for options.

end
