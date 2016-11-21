require "dotenv"
Dotenv.load rescue nil

begin
  require "pry"
rescue LoadError
end

require_relative "./extensions/bot_filter"

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end

%w(
  ask
  queue
  scoreboard
  presence
).each { |mod| require_relative "./handlers/#{mod}" }

Lita.configure do |config|
  config.robot.name         = "Marvin"
  config.robot.mention_name = "marvin"
  config.robot.locale       = :en
  config.robot.log_level    = :info
  config.robot.adapter      = :slack

  config.adapters.slack.token    = ENV.fetch("SLACK_TOKEN")
  config.robot.admins            = ENV.fetch("ADMINS").split(",")
  config.redis[:url]             = ENV.fetch("REDISTOGO_URL")
  config.http.port               = ENV.fetch("PORT", 3999)
  config.handlers.panic.hostname = ENV.fetch("URL", "http://localhost:#{config.http.port}")

  if token = ENV["ROLLBAR_ACCESS_TOKEN"]
    require "rollbar"
    Rollbar.configure do |config|
      config.access_token = token
    end
    config.robot.error_handler = ->(e) do
      Rollbar.error e
    end
  end
end
