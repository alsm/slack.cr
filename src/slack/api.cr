require "json"

class Slack
  def users
    get_json "/api/users.list", "members", Array(User)
  end

  def user_by_email(email)
    get_json "/api/users.lookupByEmail", "user", User
  end

  def conversations(limit = 100, types = "public_channel", exclude_archived = false)
    get_json "/api/conversations.list", "channels", Array(Channel), {"limit" => limit.to_s, "types" => types, "exclude_archived" => exclude_archived.to_s}
  end

  def conversation_info(conv_id, include_num_members = false)
    get_json "/api/conversations.info", "channel", Channel, {"channel" => conv_id.to_s, "include_num_members" => include_num_members.to_s}
  end

  def post_message(text : String, channel : String)
    post_message(Message.new(text: text, channel: channel))
  end

  def post_message(message : Message)
    if message.post_at.nil?
      post_json "/api/chat.postMessage", message.to_json
    else
      post_json "/api/chat.scheduleMessage", message.to_json
    end
  end

  def post_message_at(text : String, channel : String, time : Time)
    post_message(Message.new(text: text, channel: channel, post_at: time.to_utc.to_unix.to_s))
  end

  def post_ephermeral_message(text : String, channel : String, user : String)
    post_ephermeral_message(Message.new(text: text, channel: channel, user: user))
  end

  def post_ephermeral_message(message : Message)
    post_json "/api/chat.postEphermeral", message.to_json
  end

  def post_me_message(text : String, channel : String, user : String)
    post_me_message(Message.new(text: text, channel: channel, user: user))
  end

  def post_me_message(message : Message)
    post_json "/api/chat.meMessage", message.to_json
  end

  def update_message(message : Message)
    post_json "/api/chat.update", message.to_json
  end

  def delete_message(message : Message)
    post_json "/api/chat.delete", message.to_json
  end

  def scheduled_messages(channel : String, limit = 100)
    post_json "/api/chat.scheduledMessagesList", {
      "channel" => channel,
      "limit"   => limit,
    }.to_json
  end

  private def get_json(url, field, klass, params = {} of String => String)
    encoded_params = HTTP::Params.build do |form|
      form.add "token", @token
      params.each do |(k, v)|
        form.add k, v
      end
    end

    response = @client.get "#{url}?#{encoded_params}"
    handle(response) do
      parse_response_object response.body, field, klass
    end
  end

  private def parse_response_object(body, field, klass)
    error = nil

    pull = JSON::PullParser.new(body)
    pull.read_object do |key|
      case key
      when "ok"
        pull.read_bool
      when "error"
        error = pull.read_string
      when field
        return klass.new(pull)
      else
        pull.skip
      end
    end

    raise Error.new(error.not_nil!)
  end

  private def post_json(url)
    response = @client.post url
    handle(response) do
      parse_post_response(response.body)
    end
  end

  private def post_json(url, body)
    headers = HTTP::Headers{
      "Content-Type"  => "application/json",
      "Authorization" => "Bearer #{@token}",
    }
    response = @client.post url, headers, body
    handle(response) do
      parse_post_response(response.body)
    end
  end

  private def parse_post_response(body)
    error = nil
    ts = nil
    channel = nil

    pull = JSON::PullParser.new(body)
    pull.read_object do |key|
      case key
      when "ok"
        pull.read_bool
      when "error"
        error = pull.read_string
      when "ts"
        ts = pull.read_string
      when "channel"
        channel = pull.read_string
      else
        pull.skip
      end
    end

    if ts && channel
      {timestamp: ts.not_nil!, channel: channel.not_nil!}
    else
      raise Error.new(error.not_nil!)
    end
  end

  private def handle(response)
    case response.status_code
    when 200, 201
      yield
    else
      raise Error.new(response)
    end
  end
end
