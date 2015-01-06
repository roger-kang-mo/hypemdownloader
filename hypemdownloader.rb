require 'rubygems'
require 'mechanize'
require "open-uri"

USERNAME = ARGV.first
SOURCE_URL = "http://hypem.com/serve/source/"

mechanize = Mechanize.new { |agent|
  agent.user_agent_alias = 'Mac Safari'
}

pages = [""]
dest_url = "http://hypem.com/#{USERNAME}?ax=1"
track_list = []

def get_songs_for_page(url, mechanize)
  track_list = []

  mechanize.get(url) do |page|
    tracks = JSON.parse(page.search("#displayList-data").first)['tracks']

    track_list = tracks.map do |track|
      url = "#{SOURCE_URL}#{track['id']}/#{track['key']}"

      track_data = {
          artist: track['artist'],
          title: track['song'],
          post_url: track['posturl']
      }

      begin
        mechanize.get(url) do |page|
          track_url = JSON.parse(page.body)['url']

          track_data.merge({url: track_url})

          open(track_url) do |f|
            p "Downloading #{track_data[:artist]} - #{track_data[:title]}.mp3"

            File.write("#{track_data[:artist]} - #{track_data[:title]}.mp3", open(track_url).read, {mode: 'wb'})
          end
        end
      rescue Exception => e
        p "Couldn't download file #{track_data[:artist]} - #{track_data[:title]}."
      end
    end

    track_list
  end

  track_list
end

def get_pages(mechanize)
  pages = []
  current_page = 2

  mechanize.get("http://hypem.com/#{USERNAME}?ax=1") do |page|
    page_objects = page.search(".paginator").children.to_a

    page_objects.select! do |p|
      p.name == 'a' && !p.children.first.text.include?("See more")
    end

    page_objects.count.times do |t|
      pages << "/#{current_page}"
      current_page += 1
    end
  end
  pages
end

pages.concat get_pages(mechanize)

track_list = pages.map { |p| get_songs_for_page("http://hypem.com/#{USERNAME}#{p}?ax=1", mechanize) }

track_list.flatten

