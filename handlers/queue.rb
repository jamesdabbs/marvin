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

      def add_to_queue(response)
        target = response.matches.first
        queue = queue_for(target)
        queue << response.user.name
        persist_queue_for(target, queue)
        send_queue_status(response, queue)
      end

      def remove_from_queue(response)
        target = response.matches.first
        queue = queue_for(target)
        queue.delete(response.user.name)
        persist_queue_for(target, queue)
        send_queue_status(response, queue)
      end

      def next(response)
        target = response.user.name
        queue = queue_for(target)
        queue.shift
        persist_queue_for(target, queue)
        send_queue_status(response, queue)
      end

      def send_queue_status(response, queue)
        case queue.size
        when 0
          response.reply("Nobody in the queue!")
        when 1
          response.reply("Next up is @#{queue[0]}.")
        else
          response.reply("Next up is @#{queue[0]}, and then #{queue[1..-1].join(", ")}")
        end
      end

      def queue_for(target)
        queue = redis.get(target)
        queue ? JSON.parse(queue) : []
      end

      def persist_queue_for(target, queue)
        redis.set target, queue.to_json
      end
    end
    Lita.register_handler(Queue)
  end
end
