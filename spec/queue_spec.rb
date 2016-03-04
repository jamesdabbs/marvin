require "spec_helper"
require_relative "../handlers/queue"

describe Lita::Handlers::Queue, lita_handler: true do
  let(:bob) { Lita::User.create(1, mention_name: "bob") }
  let(:lilly) { Lita::User.create(2, mention_name: "lilly") } # instructor
  let(:joe) { Lita::User.create(3, mention_name: "joe") }

  before do
    bob
    lilly
    joe
  end
  
  it { is_expected.to route("question @russell").to(:add_to_queue) }
  it { is_expected.to route("question  for @russell") }
  it { is_expected.to_not route("question   #russell") }

  it { is_expected.to route("nevermind @russell") }
  it { is_expected.to_not route("nm   #russell") }

  it { is_expected.to route("next up") }

  it "lets everyone know who's in the queue when one user is waiting" do
    send_message("question for @lilly", as: bob)
    expect(replies.last).to eq("<@1> is up for lilly.")
  end

  it "lets everyone know who's in the queue" do
    send_message("question for @lilly", as: bob)
    send_message("question for @lilly", as: joe)
    expect(replies.last).to eq("<@1> is up for lilly, and then joe")
  end

  it "removes someone from the queue when they say nm" do
    send_message("question for @lilly", as: bob)
    send_message("question for @lilly", as: joe)
    send_message("nevermind @lilly", as: bob)
    expect(replies.last).to eq("<@3> is up for lilly.")
  end

  it "gets next up person" do
    send_message("question for @lilly", as: bob)
    send_message("question @lilly", as: joe)
    send_message("next up", as: lilly)
    expect(replies.last).to eq("<@3> is up for lilly.")
  end

  it "notifies the responder when queue is clear" do
    send_message("question for @lilly", as: bob)
    send_message("question @lilly", as: joe)
    send_message("next up", as: lilly)
    send_message("next up", as: lilly)
    expect(replies.last).to eq("lilly the queue is empty!")
  end
end
