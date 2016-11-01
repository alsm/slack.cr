require "../src/slack.cr"
slack = Slack.new(token: ENV["SLACK_TOKEN"])

slack.on(Slack::Event::Message) do |session, event|
  puts event.raw
end

slack.run
