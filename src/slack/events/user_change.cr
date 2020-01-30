Slack::Event.register(Slack::Event::UserChange, "user_change")

class Slack
  class Event
    # Implments https://api.slack.com/events/user_change
    class UserChange < Slack::Event
      JSON.mapping(
        type: String,
        user: User,
        team_id: String,
        name: String,
        deleted: String,
        real_name: String,
        profile: JSON::Any,
      )

      def get_profile
        @profile
      end

      def self.build(raw : JSON::Any) : Slack::Event::UserChange?
      end

      def profile
      end
    end
  end
end
