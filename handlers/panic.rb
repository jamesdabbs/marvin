require_relative "../lib/panic_store"

module Lita
  module Handlers
    class Panic < Handler
      route /^\D*(\d)\D*$/, :answer, command: true
      route /how(?: i|\')s every\w+\s*(in (\w+))?/i, :poll, command: true

      http.get "/panic" do |request, response|
        response.body << PanicStore.to_csv(redis: redis)
      end

      def poll response
        response.reply "I don't know. I'll ask them."

        channel = if name = response.matches[0][1]
          Lita::Room.find_by_name name
        else
          response.room
        end

        responders = robot.roster channel
        store_for(response.user).start_poll responders: responders
        responders.each { |user| ping_with_poll user, response }
      end

      def answer response
        store = store_for response.user
        return unless store.open? # Assume this is a false positive match?

        store.record response.message.body
        response.reply_privately "Roger, thanks for the feedback"
      end

      private

      def store_for user
        PanicStore.new user: user, redis: redis
      end

      def ping_with_poll user, response
        robot.send_message Source.new(user: user),
          "Hey, how are you doing (on a scale of 1 (boredom) to 6 (panic))?"
      rescue RuntimeError => e
        unless e.message =~ /cannot_dm_bot/
          response.reply_privately("Shoot, I couldn't reach #{user.mention_name} because we hit this bug `#{e.message}`")
        end
      end
    end

    Lita.register_handler Panic
  end
end
