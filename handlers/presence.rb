module Lita
  module Handlers
    class Observer < Handler
      on(:slack_presence_change) do |payload|
        client = Slack::Web::Client.new
        user_data = client.users_info(user: payload["user"])
        log.info "User #{user_data['user']['name']} is #{payload['presence']}"
        post_event(payload.merge(user_data))
      end

      def post_event(data)
        uri = URI(ENV["WHITETOWER_URL"])
        http = Net::HTTP.new(uri.host, uri.port)

        if ENV["WHITETOWER_URL"].starts_with? "https://"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        req = Net::HTTP::Post.new(
          uri.path,
          "Content-Type" => "application/json",
          "Authorization" => "token #{ENV['WHITETOWER_API_KEY']}"
        )
        puts data.to_json
        req.body = data.to_json
        http.request(req)
      rescue => e
        puts "failed #{e}"
      end
    end

    Lita.register_handler Observer
  end
end
