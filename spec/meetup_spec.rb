# frozen_string_literal: true
require "spec_helper"
require_relative "../handlers/meetup"

describe Lita::Handlers::Meetup, lita_handler: true do
  let!(:bob)   { build_user "bob" }
  let!(:lilly) { build_user "lilly", groups: [:instructors, :staff] }

  it { is_expected.to route("meetup next").to(:get_next_meetup) }
  it { is_expected.to route("meetup set venue 321").to(:store_venue) }
  it { is_expected.to route("meetup rsvps https://www.meetup.com/dcruby/events/235551669/").to(:get_rsvps_for_meetup_url) }

  it "provides a link to download excel only if a default venue is set" do
    send_message("meetup next", as: lilly)
    expect(replies.last).to match /set a default venue/
  end

  describe "when a venue is set" do
    before do
      send_message("meetup set venue 123", as: lilly)
    end

    it "provides a link to download excel" do
      send_message("meetup next", as: lilly)

      expect(replies.last).to eq("/meetup/venue/123")
    end
  end

  describe "when asking for download link for an event url" do
    it "parses group name and ID from url" do
      send_message("meetup rsvps https://www.meetup.com/dcruby/events/235551669/", as: lilly)

      expect(replies.last).to eq("/meetup/event/dcruby/235551669")
    end
  end

  describe "when http request to venue" do
    it "will download a excel document" do
      response = http.get("/meetup/venue/24728607")
      expect(response.body).to_not eq ""
    end
  end

  describe "when http request to event" do
    it "will download a excel document" do
      response = http.get("/meetup/event/dcruby/235551669")
      expect(response.body).to_not eq ""
    end
  end
end
