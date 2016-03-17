source "https://rubygems.org"
ruby   "2.3.0"

gem "lita"
gem "lita-howdoi"
gem "lita-panic", github: "jamesdabbs/lita-panic"

# This commit is on master; this should be safe to bump when the
# next version releases with support for `roster`
gem "lita-slack", github: "litaio/lita-slack", ref: "38a968f"
gem "dotenv"

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
