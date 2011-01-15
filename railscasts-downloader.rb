#!/usr/bin/env ruby

#load required module
require 'open-uri'
require 'nokogiri'

#get existing episodes
existing_filenames = Dir.glob('*.mov')
existing_eps_numbers = existing_filenames.map {|x| "/episodes/" + x[/\d+/].sub!(/^0*/, "") + "-"}

#get videos pages url from archive page
video_pages = []
railscasts_archive_page = "http://railscasts.com/episodes/archive"
doc = Nokogiri::HTML(open(railscasts_archive_page))
doc.search('//*[@href]').each do |m|
  episode = "http://railscasts.com" + m[:href] if m[:href].include? "episodes" 
  video_pages << episode unless episode.nil? or existing_eps_numbers.any? { |eps| episode.include? eps }
end

#load each video pages, then download the video
video_pages.each do |page|
  doc = Nokogiri::HTML(open(page))
  doc.search('//*[@href]').each do |m|
    video_url = m[:href] if m[:href].include? ".mov"
    unless video_url.nil?
      filename = video_url.split('/').last

      p "Downloading #{filename}"
      %x(wget #{video_url} -c -O #{filename}.tmp )
      %x(mv #{filename}.tmp #{filename} )
      p "Finish downloading #{filename}"
    end
  end
end

p 'Finished synchronization'

