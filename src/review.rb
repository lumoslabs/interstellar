class Review
  attr_accessor :text, :title, :submitted_at, :original_submitted_at, :rate, :device, :url, :version, :lang

  def initialize data = {}
    @text = data[:text]
    @title = data[:title]

    begin
      @submitted_at = DateTime.parse(data[:submitted_at])
    rescue ArgumentError
    end
    begin
      @original_submitted_at = DateTime.parse(data[:original_submitted_at])
    rescue ArgumentError
    end
    @rate = data[:rate].to_i
    @device = data[:device]
    @url = data[:url]
    @version = data[:version] ? "v#{data[:version]}" : nil
    @lang = data[:lang]
  end

  @@ratings = Array.new(5, 0)

  def self.collection
    @collection ||= []
  end

  def self.send_reviews_from_date(date, datefile)
    messages = collection.select { |r| r.submitted_at && r.submitted_at > date && (@@ratings[r.rate - 1] += 1) && (r.title || r.text) && r.lang == 'en' }.sort_by(&:submitted_at).map(&:build_message)

    ratings_sum = @@ratings.reduce(:+)
    if ratings_sum > 0
      # first message
      Slack.notify({
        text: [
          "#{ratings_sum} new Play Store #{ratings_sum == 1 ? 'rating' : 'ratings'}!",
          @@ratings.map.with_index{ |x, i| '★' * (i + 1) + '☆' * (4 - i) + " #{x}" }.reverse,
          "#{(@@ratings.map.with_index{ |x, i| x * (i + 1) }.reduce(:+).to_f / ratings_sum).round(3)} average rating\n",
          "#{messages.length} new Play Store #{messages.length == 1 ? 'review' : 'reviews'}!"
        ].join("\n")
      })

      # all the actual reviews
      messages.each_slice(100) do |messages_chunk|
        Slack.notify({
          text: "",
          attachments: messages_chunk
        })
      end

      IO.write(datefile, collection.max_by(&:submitted_at).submitted_at.to_time.to_i)
    else
      print "No new reviews\n"
    end
  end

  def build_message
    date = (original_submitted_at - submitted_at > 1 ? "#{original_submitted_at.strftime('%Y.%m.%d at %H:%M')}, edited on " : '') + submitted_at.strftime('%Y.%m.%d at %H:%M')
    stars = '★' * rate + '☆' * (5 - rate)
    footer = (version ? "for #{version} " : '') +"using #{device} on #{date}"

    {
      fallback: [stars, title, text, footer, url].join("\n"),
      color: ['#D36259', '#EF7E14', '#FFC105', '#BFD047', '#0E9D58'][rate - 1],
      author_name: stars,
      title: title,
      title_link: url,
      text: "#{text}\n_#{footer}_ · <#{url}|Permalink>",
      mrkdwn_in: ['text']
    }
  end
end
