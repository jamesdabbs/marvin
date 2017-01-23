# frozen_string_literal: true
module Meetup
  class Event
    attr_reader :data
    def initialize(data = {})
      @data = data
    end

    def path
      "tmp/events_rsvp_#{name_for_file}.xlsx"
    end

    def name_for_file
      data["name"].underscore.tr(" ", "_").delete(":")
    end

    def meetup_group
      data["group"]["urlname"]
    end

    def event_id
      data["id"]
    end

    def members
      @_members ||= Api.new.rsvps_for_event(meetup_group, event_id)
    end

    def as_excel
      FileUtils.rm(path) if File.exist?(path)
      SimpleXlsx::Serializer.new(path) do |doc|
        doc.add_sheet("People") do |sheet|
          sheet.add_row(["First Name", "Last Name"])
          members.each do |member|
            member = Member.new(member["member"])
            sheet.add_row [member.first_name, member.last_name]
          end
        end
      end
      File.read(path)
    end

    def self.by_id(group, id)
      new(Api.new.event(group, id))
    end
  end
end
