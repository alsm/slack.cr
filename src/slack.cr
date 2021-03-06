require "http/client"
require "http/web_socket"
require "json"
require "./slack/**"

# Handles connecting and starting Slack websocket session and delegates slack events.
# ```
# require "../src/slack.cr"
# slack = Slack.new(token: ENV["SLACK_TOKEN"])
#
# slack.on(Slack::Event::UserTyping) do |session, event|
#   puts "someone is typing 2"
# end
#
# slack.run
# ```
class Slack
  property wss : String?
  # Returns me, as the current slack user.
  property me : User?
  # Websocket connection.
  property socket : HTTP::WebSocket?
  property debug = false

  @me : User?
  @mid : Int32

  def initialize(@token : String)
    @mid = 0
    @endpoint = "slack.com"
    @client = HTTP::Client.new @endpoint, tls: true
    @callbacks = Hash(Slack::Event.class, Array(Proc(Slack, Slack::Event, Nil))).new { |h, k| h[k] = Array(Proc(Slack, Slack::Event, Nil)).new }
    start
  end

  # Binds a callback to event.
  # Allows multiple bindings to event, and will be called in order of binding
  def on(event : Slack::Event.class, &cb : Slack, Slack::Event ->)
    @callbacks[event] << cb
  end

  # Calls Slack rtm.connect method to get initial websocket connection parameters
  private def start
    client = HTTP::Client.new @endpoint, tls: true
    response = client.get("/api/rtm.connect?token=#{@token}")
    config = Slack::Hello.from_json(response.body)
    if config
      @wss = config.url
      @me = config.me
    end
    client.close
  end

  # Send a message to slack
  def send(msg : Slack::Message)
    @socket.try do |socket|
      socket.send(msg.to_json)
    end
  end

  # Send a message to slack
  def send(msg : String, to channel : String)
    send(Slack::Message.new(channel, msg))
  end

  # Start Slack RTM event loop
  def run
    @running = true

    # If a recconnect url is provided
    # * Save new url
    # * Close current connection
    on(Slack::Event::ReconnectUrl) do |session, event|
      if e = event.as?(Slack::Event::ReconnectUrl)
        if url = e.url
          puts "Setting url to #{url}"
          session.wss = url
          session.close
        end
      end
    end

    # Connect loop
    while @running
      connect
      if @running
        "Reconnecting..."
      end
    end
    puts "Disconnected"
  end

  # Close the websocket connection
  def close
  end

  # connect and run event loop
  private def connect
    begin
      if wss = @wss
        @socket = HTTP::WebSocket.new(wss)
        puts "Connected to #{wss}"
        puts
        @socket.try do |socket|
          socket.on_close do |m|
            puts "Connection closed: #{m}"
          end

          socket.on_message do |j|
            begin
              event = Slack::Event.get_event(j)
              if event
                if cbs = @callbacks[event.class]?
                  cbs.each do |cb|
                    cb.call(self, event)
                  end
                end
              elsif reply = Slack::ReplyTo.get_reply(j)
                # TODO
              end
            rescue ex
              puts "Cannot process event: #{ex.message}"
            end
          end

          socket.run
          puts "disconnected after run"
        end
      end
    rescue ex
      puts ex.message
    end
  end
end
