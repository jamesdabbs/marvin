module Lita
  module Handlers
    class Scoreboard < Handler
      route /(\S+)\+\+/, :plus, help: { "TEXT++" => "Add points" }
      route /(\S+)\-\-/, :minus, help: { "TEXT--" => "Remove points" }
      route /score (\S+)/, :score, help: { "score TEXT" => "Show points" }

      def plus response
        key    = response.matches[0][0]
        score  = redis.get(key).to_i
        score += 1
        redis.set key, score
        response.reply "#{key} now has #{score} points"
      end

      def minus response
        key    = response.matches[0][0]
        score  = redis.get(key).to_i
        score -= 1
        redis.set key, score
        response.reply "#{key} now has #{score} points"
      end

      def score response
        key   = response.matches[0][0]
        score = redis.get(key) || 0
        response.reply "#{key} has #{score} points"
      end
    end

    Lita.register_handler Scoreboard
  end
end
