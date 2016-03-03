require 'json'

module Lita
  module Handlers
    class Queue < Handler
      route(
        /^question\s*(?:for)?\s*\@?(\w+)/,
        :add_to_queue,
        help: { "question USER" => "add to queue for USER." }
      )

      route(
        /^(?:nevermind|nm)\s*\@?(\w+)/,
        :remove_from_queue,
        help: { "nevermind USER" => "remove SENDER from queue for USER." }
      )

      route(
        /next up/,
        :next,
        help: { "next up" => "removes oldest user from queue and ping group" }
      )

      def add_to_queue(msg)
        target = Lita::User.find_by_mention_name msg.matches[0][0]
        queue = queue_for(target.id)
        queue << msg.user.id
        persist_queue_for(target.id, queue)
        annouce_to_room(target, msg, queue)
      end

      def remove_from_queue(msg)
        target = Lita::User.find_by_mention_name msg.matches[0][0]
        queue = queue_for(target.id)
        queue.delete(msg.user.id)
        persist_queue_for(target, queue)
        annouce_to_room(target, msg, queue)
      end

      def next(msg)
        target = Lita::User.find_by_id msg.user.id
        queue = queue_for(target)
        queue.shift
        persist_queue_for(target, queue)
        annouce_to_room(target, msg, queue)
      end

    private

        def annouce_to_room(responder, msg, queue)
          case queue.size
          when 0
            msg.reply("#{mention_name responder.id} the queue is empty!")
          when 1
            msg.reply("#{slack_notifer queue[0]} is up for #{mention_name responder.id}.")
          else
            msg.reply("#{slack_notifer queue[0]} is up for #{mention_name responder.id}, and then #{queue[1..-1].map{|u| mention_name u}.join(", ")}")
          end
        end

        def queue_for(target)
          queue = redis.get(target)
          queue ? JSON.parse(queue) : []
        end

        def persist_queue_for(target, queue)
          redis.set target, queue.to_json
        end

        def slack_notifer(id, type: :user)
          char = type == :user ? '@' : "#"
          "<#{char}#{id}>"
        end

        def mention_name(id)
          Lita::User.find_by_id(id).mention_name
        end
    end
    Lita.register_handler(Queue)
  end
end
