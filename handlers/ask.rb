module Lita
  module Handlers
    class Ask < Handler
      route /^ask (\#?\@?\w+) (.*)/, :ask,
        help: { "ask (user|channel) (text)" => "Privately forwards a question" }

      def ask response
        target, question = response.matches[0]
        if dest = source(target)
          robot.send_message dest, "Someone was wondering: #{question}"
        else
          response.reply "Sorry - I don't know how to reach #{target}"
        end
      end

      private

      def source target
        if target.start_with? "@"
          user target[1 .. -1]
        elsif target.start_with? "#"
          room target[1 .. -1]
        else
          user(target) || room(target)
        end
      end

      def user target
        if u = Lita::User.find_by_mention_name(target)
          Source.new user: u
        end
      end

      def room target
        if r = Lita::Room.find_by_name(target)
          Source.new room: r
        end
      end
    end

    Lita.register_handler Ask
  end
end
