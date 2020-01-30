Slack::Event.register(Slack::Event::MemberLeftChannel, "member_left_channel")

class Slack
  class Event
    # Implements https://api.slack.com/events/member_left_channel
    class MemberLeftChannel < Slack::Event
      @@type = "member_left_channel"
      JSON.mapping(
        type: String,
        user: String,
        channel: String,
        channel_type: String,
        team: String,
      )
    end
  end
end
