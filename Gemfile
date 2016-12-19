source "https://rubygems.org"
git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }
ruby   "2.3.3"

gem "lita"
gem "lita-howdoi"
gem "lita-panic", github: "jamesdabbs/lita-panic"
# gem "lita-panic", path: "/Users/rposborne/code/lita-panic"

# This commit is on master; this should be safe to bump when the
# next version releases with support for `roster`
gem "lita-slack", github: "rposborne/lita-slack", branch: "always-trigger-event"
gem "dotenv"
gem "slack-ruby-client"

group :development do
  gem "pry"
end

group :test do
  gem "coveralls"
  gem "rspec"
  gem "rack-test"
  gem "simplecov"
end

group :production do
  gem "rollbar"
end
