require 'pry'

class ResponderQueue
  attr_reader :responder, :redis

  def initialize(for_user, redis)
    @responder = for_user
    @redis = redis
  end

  def add(user)
    redis.rpush responder.id, user.id
    self
  end

  def remove(user)
    redis.lrem responder.id, 0 , user.id
    self
  end

  def next
    redis.lpop responder.id
    self
  end

  def queue
    redis.lrange(responder.id, 0, -1)
  end

  class << self
    def for(user, redis)
      self.new(user, redis)
    end
  end
end


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
        responder = Lita::User.find_by_mention_name msg.matches[0][0]
        queue = ResponderQueue.for(responder, redis).add msg.user

        annouce_to_room(responder, msg, queue.queue)
      end

      def remove_from_queue(msg)
        responder = Lita::User.find_by_mention_name msg.matches[0][0]
        queue = ResponderQueue.for(responder, redis).remove(msg.user)

        annouce_to_room(responder, msg, queue.queue)
      end

      def next(msg)
        responder = Lita::User.find_by_id msg.user.id
        queue = ResponderQueue.for(responder, redis).next

        annouce_to_room(responder, msg, queue.queue)
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
