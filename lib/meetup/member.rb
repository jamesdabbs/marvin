# frozen_string_literal: true
module Meetup
  class Member
    def initialize(data)
      @data = data
    end

    def name
      @data["name"]
    end

    def first_name
      if name.include?(" ")
        name.split(" ", 3).first
      else
        name
      end
    end

    def last_name
      if name.include?(" ")
        name.split(" ", 3).last
      else
        ""
      end
    end
  end
end
