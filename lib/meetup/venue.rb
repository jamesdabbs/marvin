# frozen_string_literal: true
module Meetup
  class Venue
    attr_reader :venue_id
    def initialize(venue_id)
      @venue_id = venue_id
    end

    def events
      @_events ||= Meetup::Api.new.events_for_venue_id(venue_id)["results"]
    end

    def next_event
      @_next_event ||= events.first
    end
  end
end
