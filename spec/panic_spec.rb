require "spec_helper"
require_relative "../handlers/panic"

describe Lita::Handlers::Panic, lita_handler: true do
  let(:bob) { Lita::User.create(1, mention_name: "bob") }
  let(:lilly) { Lita::User.create(2, mention_name: "lilly") } # instructor
  let(:joe) { Lita::User.create(3, mention_name: "joe") }

  before do
    bob
    lilly
    joe
  end

  it { is_expected.to route("how is everyone doing?").to(:poll) }

  describe "#poll" do
    before do
      allow(robot).to receive(:roster).and_return([1,2])
    end

    it "asks everyony how they are doing" do
      send_message("how is everyone doing?", as: lilly, from: Lita::Room.create_or_update("#lita.io"))
      expect(replies.size).to eq 3
      expect(replies.first).to eq "I don't know. I'll ask them."
      expect(replies.last).to eq "Hey, how are you doing (on a scale of 1 (boredom) to 6 (panic))?"
    end

    describe "error handling" do
      it "will silence cannot_dm_bot errors" do
        expect_any_instance_of(described_class).to receive(:take_temperature).twice.and_raise("Slack API call to im.open returned an error: cannot_dm_bot.")
        send_message("how is everyone doing?", as: lilly, from: Lita::Room.create_or_update("#lita.io"))
        expect(replies.size).to eq 1
        expect(replies.first).to eq "I don't know. I'll ask them."
      end

      it "will respond with other errors" do
        expect_any_instance_of(described_class).to receive(:take_temperature).twice.and_raise("BOOM")
        send_message("how is everyone doing?", as: lilly, from: Lita::Room.create_or_update("#lita.io"))
        expect(replies.size).to eq 3
        expect(replies.first).to eq "I don't know. I'll ask them."
        expect(replies.last).to eq "Shoot, I couldn't reach lilly because we hit this bug `BOOM`"
      end
    end
  end
end
