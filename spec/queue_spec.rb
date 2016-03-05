require "spec_helper"
require_relative "../handlers/queue"

describe Lita::Handlers::Queue, lita_handler: true do
  let!(:bob)   { build_user "bob" }
  let!(:lilly) { build_user "lilly", groups: [:instructors, :staff] }
  let!(:joe)   { build_user "joe" }

  it { is_expected.to route("question @russell").to(:add_to_queue) }
  it { is_expected.to route("question  for @russell") }
  it { is_expected.to_not route("question   #russell") }

  it { is_expected.to route("nevermind @russell") }
  it { is_expected.to_not route("nm   #russell") }

  it { is_expected.to route("next up").with_authorization_for(:instructors) }

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
