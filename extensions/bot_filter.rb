module Lita
  module Extensions
    class BotFilter
      def self.call(payload)
        return true if payload[:route].extensions[:ignore_bots] == false

        bot, m = payload[:robot], payload[:message]
        if m.source && m.source.user && m.source.user.mention_name == bot.mention_name
          return false
        end
        return true
      rescue StandardError => e
        puts "Error in BotFilter: #{e}" # Don't want to crash the bot here
      end
    end

    Lita.register_hook :validate_route, BotFilter
  end
end
