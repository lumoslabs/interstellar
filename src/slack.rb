require 'httparty'

class Slack
  def self.notify(message)
    HTTParty.post ENV['SLACK_URL'], {
      payload: message.to_json
    },
    content_type: :json,
    accept: :json
  rescue => e
    puts e.response
  end
end
