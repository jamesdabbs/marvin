require "csv"
require "securerandom"

class PanicDB
  class << self
    def export_token_for user, redis:
      tokens = redis.hgetall "export_tokens"
      if token = tokens[user.id]
        token
      else
        token = SecureRandom.uuid
        redis.hset "export_tokens", user.id, token
        token
      end
    end

    def user_from_token token, redis:
      tokens = redis.hgetall "export_tokens"
      tokens.keys.find { |user_id| tokens[user_id] == token }
    end

    def to_csv redis:
      polls = redis.keys.
              select  { |k| k.start_with?("poll:") }.
              map     { |k| Poll.new key: k, redis: redis }.
              sort_by { |p| p.created_at }

      user_ids = polls.map(&:responder_ids).flatten.uniq

      CSV.generate do |csv|
        csv << ["User"] + polls.map { |p| p.created_at }

        user_ids.each do |id|
          user = Lita::User.find_by_id id
          csv << [user.name] + polls.map { |poll| poll.response_from(id) }
        end
      end
    end
  end

  class Poll
    class << self
      def create poster:, responders:, redis:
        start    = Time.now.to_f
        finish   = start.to_i + 12 * 60 * 60
        poll_key = "poll:#{poster.id}:#{start}"

        values = responders.map { |r| [r.id, ""] }.flatten
        redis.hmset poll_key, *values
        responders.each { |r| redis.setex "open:#{r.id}", finish, poll_key }
      end

      def for user:, redis:
        key = redis.get "open:#{user.id}"
        Poll.new(key: key, redis: redis) if key
      end
    end

    def initialize key:, redis:
      @key, @redis = key, redis
      pref, @poster_id, @at = key.split ":"
      raise "Invalid poll key: #{key}" unless pref == "poll"
    end

    def poster
      @_poster ||= Lita::User.find_by_id(poster_id)
    end

    def created_at
      @_created_at ||= Time.at Float(at)
    end

    def record user:, response:
      redis.hset key, user.id, response
    end

    def complete?
      missing = redis.hgetall(key).select { |id, response| response.empty? }
      (missing.keys - [poster_id.to_s]).empty?
    end

    def to_h
      @_to_h ||= redis.hgetall(key).freeze
    end

    def responder_ids
      redis.hkeys key
    end

    def response_from id
      to_h[id]
    end

    private

    attr_reader :key, :redis, :poster_id, :at
  end
end
