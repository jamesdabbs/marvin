require_relative "../lib/panic_store"

module Lita
  module Handlers
    class Panic < Handler
      route /^\D*(\d)\D*$/, :answer, command: true
      route /how(?: i|\')s every\w+\s*(in (\w+))?/i, :poll, command: true

      http.get "/panic" do |request, response|
        response.body << PanicStore.to_csv(redis: redis)
      end

      def poll msg
        msg.reply "I don't know. I'll ask them."

        channel = if name = msg.matches[0][1]
          Lita::Room.find_by_name name
        else
          msg.room
        end

        responders = robot.roster channel
        store.start_poll poster: msg.user, responders: responders
        responders.each { |user| ping_with_poll user, msg }
      end

      def answer msg
        poll = store.poll_for msg.user
        return unless poll # Assume this is a false positive match?

        poll.record user: msg.user, response: msg.message.body
        msg.reply_privately "Roger, thanks for the feedback"

        if poll.complete?
          robot.send_message Source.new(user: poll.poster), "The results are in"
        end

        score = msg.matches[0][0].to_i
        if score > 4
          robot.send_message Source.new(user: poll.poster), "#{msg.user.mention_name} is at a #{score}"
        end
      end

      private

      def store
        @_store ||= PanicStore.new(redis)
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
