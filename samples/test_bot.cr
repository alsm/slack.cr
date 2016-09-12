require "../src/slack.cr"
slack = Slack.new(token: ENV["SLACK_TOKEN"])

slack.add_callback(Slack::Event::Message, Proc(Slack, Slack::Event, Nil).new do |session, event|
  if event = event.as?(Slack::Event::Message) # weird casting here.. can i put it in slack.cr?
    if session.me.as?(Slack::User)
      puts "Here as User! #{event.class.to_s} #{event.test}"
      if event.mentions(session.me)
        x = event.reply(text: "oh hi there")
        session.send x
      end

      if event.mentions("good morning", "good evening")
        if event.mentions(session.me)
          x = event.reply(text: "<@#{event.user}>: to you too!")
        else
          x = event.reply(text: "thank you!")
        end
        session.send x
      end
    end
  end
end)

slack.add_callback(Slack::Event::Message, Proc(Slack, Slack::Event, Nil).new do |session, event|
  if event = event.as?(Slack::Event::Message) # weird casting here.. can i put it in slack.cr?
    x = event.reply(text: "callback 2")
    session.send x
  end
end)

slack.add_callback(Slack::Event::UserTyping, Proc(Slack, Slack::Event, Nil).new do |session, event|
  puts "someone is typing"
end)

slack.on_user_typing do |session, event|
  puts "Someone is typing"
end

slack.on_user_change do |session, event|
  puts "User changed"
  pp event
end

slack.add_callback(Slack::Event::StarAdded, Proc(Slack, Slack::Event, Nil).new do |session, event|
  puts "starred"
end
)
slack.add_callback(Slack::Event::PinAdded, Proc(Slack, Slack::Event, Nil).new do |session, event|
  puts "pin added"
end
)

slack.add_callback(Slack::Event::Ready, Proc(Slack, Slack::Event, Nil).new do |session, event|
  hello = %[{
  "id": #{@mid += 1}
  "type": "message",
  "channel": "C1B6MMY7L",
  "text" : "hello"
  }]
  message = "Hello #{Time.now.to_s}"
  r = Slack::Message.new(channel: "C1B6MMY7L", text: message).to_json
  slack.send r
end
)

slack.add_callback(Slack::Reconnect, Proc(Slack, Slack::Event, Nil).new do |session, event|
  puts "pin added"
end
)

slack.run
