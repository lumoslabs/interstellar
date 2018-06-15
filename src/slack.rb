require 'httparty'

class Slack
  def self.notify(message)
    HTTParty.post(ENV['SLACK_URL'],
      body: message.to_json,
      headers: {'Content-Type'=>'application/json'}
    )
  end
end
