require 'json'
require 'date'
require 'csv'
require 'enumerator'
require 'google/cloud/storage'
require 'open-uri'
require 'dotenv/load'
require_relative 'review'
require_relative 'slack'

class ReviewPoster
  attr_accessor :datefile, :default_days_back

  def initialize
    @datefile = './lastdate'
    @default_days_back = 4
  end

  def download_recent_files
     # credentials and project are in ENV
     storage = Google::Cloud::Storage.new
     bucket = storage.bucket(ENV['APP_REPO'])
     year_month = Date.today.strftime('%Y%m')
     csv_file_name = "reviews_#{ENV["PACKAGE_NAME"]}_#{year_month}.csv"
     review_files = bucket.files prefix: "reviews/#{csv_file_name}"
     review_files.each do |rf|
       rf.download rf.name
     end
     review_files.map(&:name)
  end

  def process
    device = Hash.new

    csv_text = open('http://storage.googleapis.com/play_public/supported_devices.csv')
    CSV.foreach(csv_text, :encoding => 'bom|utf-16le:utf-8', :headers => true, :header_converters => :symbol) do |row|
      begin
        name = row[:marketing_name] || row[:model] || row[:device]
        if device[row[:device]]
          device[row[:device]] = "#{device[row[:device]]}/#{name}" if device[row[:device]].index(name).nil?
        else
          device[row[:device]] = !row[:retail_branding].nil? && name.downcase.tr('^a-z0-9', '').index(row[:retail_branding].downcase.tr('^a-z0-9', '')).nil? ? "#{row[:retail_branding]} #{name}" : name
        end
        device[row[:device]] = device[row[:device]].gsub('\t', '').gsub("\\'", "'").gsub('\\\\', '/').gsub(/(\\x[\da-f]{2}+)/) { [$1.tr('^0-9a-f','')].pack('H*').force_encoding('utf-8') }
      rescue => e
        puts "error while parsing: #{e}"
      end
    end

    csv_file_names = download_recent_files
    csv_file_names.each do |csv_file_name|
      # ruby 2.5 can't parse with this file type
      # https://github.com/ruby/csv/issues/23
      CSV.foreach(csv_file_name, :encoding => 'bom|utf-16le:utf-8', :headers => true, :header_converters => :symbol) do |row|
        # If there is no reply - push this review
        if row[:developer_reply_date_and_time].nil?
          Review.collection << Review.new({
            text: row[:review_text],
            title: row[:review_title],
            submitted_at: row[:review_last_update_date_and_time],
            original_submitted_at: row[:review_submit_date_and_time],
            rate: row[:star_rating],
            device: device[row[:device]] ? device[row[:device]].downcase.tr('^a-z0-9', '').index(row[:device].downcase.tr('^a-z0-9', '')).nil? ? "#{device[row[:device]]} (#{row[:device]})" : device[row[:device]] : row[:device],
            url: row[:review_link],
            version: row[:app_version_name] || row[:app_version_code],
            lang: row[:reviewer_language]
          })
        end
      end
    end

    start_date = [Time.at(File.exist?(datefile) ? IO.read(datefile).to_i : 0).to_datetime, Date.today.to_datetime - default_days_back + Rational(4, 24)].max
    Review.send_reviews_from_date(start_date, datefile)
  end
end
