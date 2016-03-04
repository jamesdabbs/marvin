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
