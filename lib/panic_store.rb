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

  class Poll
    def initialize key:, redis:
      @key, @redis = key, redis
      pref, @poster_id, @at = key.split ":"
      raise "Invalid poll key: #{key}" unless pref == "poll"
    end

    def poster
      @_poster ||= Lita::User.find_by_id(poster_id)
    end

    def record user:, response:
      redis.hset key, user.id, response
    end

    def complete?
      missing = redis.hgetall(key).select { |id, response| response.empty? }
      (missing.keys - [poster_id.to_s]).empty?
    end

    private

    attr_reader :key, :redis, :poster_id
  end

  def initialize redis
    @redis = redis
  end

  def start_poll poster:, responders:
    start    = Time.now.to_f
    finish   = start.to_i + 12 * 60 * 60
    poll_key = "poll:#{poster.id}:#{start}"

    args = [poll_key] + responders.map { |r| [r.id, ""] }.flatten
    redis.hmset *args
    responders.each { |r| redis.setex "open:#{r.id}", finish, poll_key }
  end

  def poll_for user
    key = redis.get "open:#{user.id}"
    Poll.new(key: key, redis: redis) if key
  end

  private

  attr_reader :redis
end
