class Slack
  def self.notify(message)
    RestClient.post ENV['SLACK_URL'], {
      payload: message.to_json
    },
    content_type: :json,
    accept: :json
  rescue => e
    puts e.response
  end
end
