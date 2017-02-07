# frozen_string_literal: true
require_relative "../lib/meetup"

module Lita
  module Handlers
    class Meetup < Handler
      config :hostname, type: String, required: false

      route /meetup tonight/, :get_tonights_meetup,
            help: { "meetup tonight" => "Get a link to tonights meetup at the stored venue" }

      route /meetup set venue (\d+)/, :store_venue,
            help: { "meetup set venue 123" => "Set the default venue for getting tonights meetup" }

      route /meetup rsvps (https?:\/\/[\S]+)/, :get_rsvps_for_meetup_url,
            help: { "meetup rsvps https://www.meetup.com/dcruby/events/235551669/" => "Get an rsvp list for the linked meetup" }

      http.get "/meetup/venue/:venue_id" do |request, response|
        venue_id = request.env["router.params"][:venue_id]
        response.header['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        response.write ::Meetup::Event.new(::Meetup::Venue.new(venue_id).next_event).as_excel
      end

      http.get "/meetup/event/:group/:event_id" do |request, response|
        group = request.env["router.params"][:group]
        id = request.env["router.params"][:event_id]
        response.header['Content-Type']= "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        response.write ::Meetup::Event.by_id(group, id).as_excel
      end

      def store_venue(msg)
        meetup_id = msg.matches[0][0]
        redis.set "meetup_venue_id", meetup_id
        msg.reply "Venue ID is now #{meetup_id}"
      end

      def get_rsvps_for_meetup_url(msg)
        url = URI(msg.matches[0][0])
        group_name, event_id = url.path.dup.delete("/").split("events")

        msg.reply_privately "#{config.hostname}/meetup/event/#{group_name}/#{event_id}"
      end

      def get_tonights_meetup(msg)
        if default_venue
          msg.reply_privately "#{config.hostname}/meetup/venue/#{default_venue}"
        else
          msg.reply_privately "Please set a default venue ID ie.,`meetup set venue 3641`"
        end
      end

      def default_venue
        redis.get("meetup_venue_id")
      end
    end

    Lita.register_handler Meetup
  end
end
