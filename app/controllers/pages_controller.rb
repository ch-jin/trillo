class PagesController < ApplicationController
  include HTTParty

  TODAY_URL = 'http://www.reddit.com/r/earthporn.json'
  TOP_URL = 'http://www.reddit.com/r/earthporn/top/.json'
  BASE_OWM_URL = 'http://api.openweathermap.org/data/2.5/forecast?zip='
  OWM_API_KEY = '&APPID=f395d1d46337b5604db0cd7ea9ee7b4a'

  def home
    today_data = find_and_parse_json(TODAY_URL)
    @post = set_pic(today_data)
    @location_data = get_location(request.remote_ip)
    set_time_zone(@location_data)
    weather_data = find_weather_data(@location_data["zip_code"])[:list]
    @weather_display = weather_data[0..3].map do |snippet|
      compile_weather_info(snippet)
    end
  end

  private
  def find_and_parse_json(url)
    response = HTTParty.get(url).body
    JSON.parse(response.to_s, symbolize_names: true)
  end

  def any_pic_of_size?(input_json, size)
    pic_info = {}
    found_post = input_json[:data][:children].detect do |post|
      post[:data][:preview][:images][0][:source][:width] >= size
    end
    if found_post.nil?
      nil
    else
      pic_info[:url] = found_post[:data][:preview][:images][0][:source][:url]
      pic_info[:title] = found_post[:data][:title]
      pic_info
    end
  end

  def default_top_pic(input_json)
    pic_info = {}
    pic_info[:url] = input_json[:data][:children][0][:data][:preview][:images][0][:source][:url]
    pic_info[:title] = input_json[:data][:children][0][:data][:title]
    pic_info
  end

  def set_pic(data)
    if any_pic_of_size?(data, 1920).nil?
      default_top_pic(find_and_parse_json(TOP_URL))
    else
      any_pic_of_size?(data, 1920)
    end
  end

  def find_weather_data(zip_code)
    find_and_parse_json(BASE_OWM_URL + zip_code + OWM_API_KEY)
  end

  def set_time_zone(location_data)
    Time.zone = location_data["time_zone"]
  end

  def compile_weather_info(weather_snippet)
    date_time = Time.at(weather_snippet[:dt].to_i)
    return {
      date: %Q(#{date_time.strftime("%A")} #{date_time.month}/#{date_time.day}),
      time: am_pm(date_time.hour),
      temp: K_to_F(weather_snippet[:main][:temp]),
      weather: weather_snippet[:weather][0][:main],
      description: weather_snippet[:weather][0][:description],
      id: weather_snippet[:weather][0][:id]
    }
  end

  def am_pm(time)
    time.to_i < 12 ? %Q(#{time}:00 AM) : %Q(#{time - 12}:00 PM)
  end

  def K_to_F(kelvin)
    temp = (((9.0 / 5) * (kelvin.to_f - 273)) + 32).round
  end

  def get_location(ip)
    ip = "72.229.28.185" if Rails.env.development?
    MockRequest.new({"HTTP_X_REAL_IP" => ip}).location.data
  end

  def weather_icon(id)
    File.read()
  end

  class MockRequest < Rack::Request
    include Geocoder::Request
    def initialize(headers={}, ip="")
      super_env = headers
      super_env.merge!({'REMOTE_ADDR' => ip}) unless ip == ""
      super(super_env)
    end
  end
end
