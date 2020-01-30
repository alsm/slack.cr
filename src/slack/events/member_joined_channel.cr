Slack::Event.register(Slack::Event::MemberJoinedChannel, "member_joined_channel")

class Slack
  class Event
    # Implements https://api.slack.com/events/member_joined_channel
    class MemberJoinedChannel < Slack::Event
      @@type = "member_joined_channel"
      JSON.mapping(
        type: String,
        user: String,
        channel: String,
        channel_type: String,
        team: String,
        inviter: String?,
      )
    end
  end
end
