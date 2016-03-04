require "lita/rspec"
begin
  require "pry"
rescue LoadError
end

class TestMessage < SimpleDelegator
  attr_reader :to, :body

  def initialize to:, body:
    @to, @body = to, body.clone.freeze
    super body
  end

  def inspect
    %|<Message("#{body}", to: #{to.user ? to.user.name : to.room.name})>|
  end

  def == other
    case other
    when String
      body == other
    when TestMessage
      to == other.to && body == other.body
    else
      raise "Can't compare #{self.class} with #{other.class}"
    end
  end
end

class Lita::Adapters::Test
  def send_messages _target, strings
    sent_messages.concat strings.map { |s| TestMessage.new to: _target, body: s }
  end
end

module Lita::RSpec::Handler
  def replies_to user
    replies.select { |r| r.to.user == user }
  end
end


Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.warnings = false
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = ENV.fetch("RSPEC_PROFILE_COUNT", 10).to_i
  config.order = :random
  Kernel.srand config.seed
end
