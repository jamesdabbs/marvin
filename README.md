# Setup

* Clone it
* `bundle install && bundle exec lita`
* Add environment variables until it boots

# TODO

* check on [room] - DMs each member of room for a panic score (1-6) and records it
  - Creates a checkin in redis
  - Responses get associated with the last checkin (< 12 hours ago)
  - Export CSV from obfuscated (admin only) endpoint