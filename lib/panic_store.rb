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
