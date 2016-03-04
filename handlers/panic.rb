require "csv"

class PanicStore
  def self.to_csv users: nil, redis:
    user_ids = if users
      users.map &:id
    else
      redis.keys.reject { |k| k.end_with? ":open" }
    end

    # TODO: clean this up, present more readible data, serve via web
    responses    = user_ids.map { |id| [id, redis.hgetall(id)] }.to_h
    prompt_times = responses.values.map(&:keys).flatten.uniq.sort

    CSV.generate do |csv|
      csv << ["user_id"] + prompt_times.map do |t|
        Time.at t.to_i
      end

      responses.each do |id, response_map|
        user = Lita::User.find_by_id id
        csv << [user.name] + prompt_times.map { |t| response_map[t] }
      end
    end
  end

  def initialize user:, redis:
    @user, @redis = user, redis
  end

  def open! time
    redis.setex open_key, expiration(time), time
    redis.hset user.id, time, ""
  end

  def record response
    open_at = redis.getset(open_key, "").to_s
    redis.hset user.id, open_at, response unless open_at.empty?
  end

  def open?
    !redis.get(open_key).to_s.empty?
  end

  def to_h
    redis.hgetall user.id
  end

  private

  def open_key
    "#{user.id}:open"
  end

  def expiration time
    time + 12 * 60 * 60
  end

  attr_reader :user, :redis
end

module Lita
  module Handlers
    class Panic < Handler
      route /^\D*(\d)\D*$/, :answer
      route /how is every\w+ (in (\w+))?/, :poll

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

        ts = Time.now.to_i
        robot.roster(channel).each do |user_id|
          user = User.find_by_id(user_id)
          begin
            take_temperature user, at: ts
          rescue RuntimeError => e
            unless e.message =~ /cannot_dm_bot/
              response.reply_privately("Shoot, I couldn't reach #{user.mention_name} because we hit this bug `#{e.message}`")
            end
          end
        end
      end

      def answer response
        store = store_for response.user
        return unless store.open? # Assume this is a false positive match?

        store.record response.message.body
        response.reply "Roger, thanks for the feedback"
      end

      private

      def store_for user
        PanicStore.new user: user, redis: redis
      end

      def take_temperature user, at:
        store_for(user).open! at
        # TODO: don't message bots
        robot.send_message Source.new(user: user),
          "Hey, how are you doing (on a scale of 1 (boredom) to 6 (panic))?"
      end
    end

    Lita.register_handler Panic
  end
end
