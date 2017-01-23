# frozen_string_literal: true
require "httparty"
module Meetup
  class Api
    include HTTParty
    base_uri "https://api.meetup.com"
    # debug_output $stdout

    def initialize
      @options = { query: {
        format: "json",
        "photo-host" => "public",
        key: ENV["MEETUP_API_KEY"],
        sign: true
      } }
    end

    def events_for_venue_id(venue_id)
      endpoint_options = {
        offset: "0",
        limited_events: "False",
        page: "20",
        venue_id: venue_id,
        order: "time",
        desc: "false",
        status: "upcoming"
      }

      query_options = @options[:query].merge(endpoint_options)
      options = @options.merge(query: query_options)
      self.class.get("/2/events", options)
    end

    def rsvps_for_event(group, event_id)
      endpoint_options = {
        offset: "0",
        page: "150",
        order: "name"
      }

      query_options = @options[:query].merge(endpoint_options)
      options = @options.merge(query: query_options)
      self.class.get("/#{group}/events/#{event_id}/rsvps", options)
    end

    def event(group, event_id)
      endpoint_options = {
        offset: "0",
        page: "150",
        order: "name"
      }

      query_options = @options[:query].merge(endpoint_options)
      options = @options.merge(query: query_options)
      self.class.get("/#{group}/events/#{event_id}", options)
    end
  end
end
