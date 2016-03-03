require "spec_helper"
require_relative "../handlers/queue"

describe Lita::Handlers::Queue, lita_handler: true do
  it { is_expected.to route("question @russell").to(:add_to_queue) }
  it { is_expected.to route("question  for @russell") }
  it { is_expected.to_not route("question   #russell") }

  it { is_expected.to route("nevermind @russell") }
  it { is_expected.to_not route("nm   #russell") }

  it { is_expected.to route("next up") }

  it "lets everyone know who's in the queue when one user is waiting" do
    bob = Lita::User.create(1, name: "bob")
    lilly = Lita::User.create(2, name: "lilly")
    send_message("question for @lilly", as: bob)
    expect(replies.last).to eq("Next up is @bob.")
  end

  it "lets everyone know who's in the queue" do
    bob = Lita::User.create(1, name: "bob")
    lilly = Lita::User.create(2, name: "lilly")
    joe = Lita::User.create(3, name: "joe")
    send_message("question for @lilly", as: bob)
    send_message("question for @lilly", as: joe)
    expect(replies.last).to eq("Next up is @bob, and then joe")
  end

  it "removes someone from the queue when they say nm" do
    bob = Lita::User.create(1, name: "bob")
    lilly = Lita::User.create(2, name: "lilly")
    joe = Lita::User.create(3, name: "joe")
    send_message("question for @lilly", as: bob)
    send_message("question for @lilly", as: joe)
    send_message("nevermind @lilly", as: bob)
    expect(replies.last).to eq("Next up is @joe.")
  end

  it "gets next up person" do
    bob = Lita::User.create(1, name: "bob")
    lilly = Lita::User.create(2, name: "lilly")
    joe = Lita::User.create(3, name: "joe")
    send_message("question for @lilly", as: bob)
    send_message("question @lilly", as: joe)
    send_message("next up", as: lilly)
    expect(replies.last).to eq("Next up is @joe.")
  end
end
