require 'json'

class PagesController < ApplicationController
  include HTTParty
  TODAY_URL = 'http://www.reddit.com/r/earthporn.json'
  TOP_URL = 'http://www.reddit.com/r/earthporn/top/.json'

  def home
    today_data = find_and_parse_json(TODAY_URL)
    @post_url = any_pic_of_size?(today_data, 1920)
    @post_url = default_top_pic(find_and_parse_json(TOP_URL)) if @post_url.nil?
  end

  private
  def find_and_parse_json(url)
    response = HTTParty.get(url).body
    JSON.parse(response.to_s, symbolize_names: true)
  end

  def any_pic_of_size?(input_json, size)
    found_post = input_json[:data][:children].detect do |post|
      post[:data][:preview][:images][0][:source][:width] >= size
    end
    if found_post.nil?
      nil
    else
      found_post[:data][:preview][:images][0][:source][:url]
    end
  end

  def default_top_pic(input_json)
    input_json[:data][:children][0][:data][:preview][:images][0][:source][:url]
  end
end
