#!/usr/bin/env ruby

###############################################################################
#
# RailsCasts Downloader 0.2
#
# Copyright (C) 2011 Donny Kurnia <donnykurnia@gmail.com>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses>.
#
###############################################################################

#load required modules
require 'open-uri'
require 'nokogiri'
require 'yaml'

#constants
BASE_URL = 'http://railscasts.com'
VIDEO_PAGE_CACHE_FILE = 'video_page_cache.yml'

# to download PRO casts, you need to set your token
# To find your token if needed, log in to railscasts.com, click any subscription railscast, then clicking "Download .mp4"
# Video will then play in the browser, look at URL and you'll notice the token 

# leave blank if you dont have one, like: 
# TOKEN = ""
TOKEN = "" 

# standard casts link format, example : "http://media.railscasts.com/assets/episodes/videos/382-tagging.mp4"
# pro link casts link format, example : "http://media.railscasts.com/assets/subscriptions" + TOKEN + "/videos/380-memcached-dalli.mp4

def get_video_pages(page, video_pages, video_page_cache)
  cache_hit = false
  p "Reading #{page} ..."
  doc = Nokogiri::HTML(open(page))
  doc.search('//*[@href]').each do |m|
    episode = BASE_URL + m[:href] if m[:href].include?("episodes") && ! m[:href].include?("?")
    unless episode.nil? or video_pages.include?(episode)
      video_pages << episode
      cache_hit = video_page_cache.include? episode
    end
  end
  next_page_link = doc.search('//a[@class = "next_page"]')[0]
  if next_page_link and ! cache_hit
    video_pages = get_video_pages(BASE_URL + next_page_link[:href], video_pages, video_page_cache)
  end
  video_pages
end

def download_videos(video_pages, existing_eps_numbers)
  
  found = false
  
  video_pages.each do |page|
    unless existing_eps_numbers.any? { |eps| page.include? eps }
      p "will download #{page}"
      doc = Nokogiri::HTML(open(page))
      doc.search('//*[@href]').each do |m|
        video_url = m[:href] if m[:href].match ".mp4$"
        unless video_url.nil?
          filename = video_url.split('/').last

          p "Downloading #{filename}"          
          %x(wget #{video_url} -c -O #{filename}.tmp )
          %x(mv #{filename}.tmp #{filename} )
          p "Finish downloading #{filename}"
          
          found = true
        end
      end
      
      # try pro link, after having searched the page for standard.
      # since for some reason the .mp4 links are not showing in the source for subscriptions
      # construct the url manually, using token
      if !found
        filename = page.split('/').last + ".mp4"
        video_url = "http://media.railscasts.com/assets/subscriptions/" + TOKEN + "/videos/" + filename
        
        p "Downloading PRO #{filename}"          
        %x(wget #{video_url} -c -O #{filename}.tmp )
        %x(mv #{filename}.tmp #{filename} )
        p "Finish downloading #{filename}"
      end
      
      #reset flag for next iteration
      found = false
      
    end
  end
end

#load video page cache
video_page_cache = YAML::load(File.open(VIDEO_PAGE_CACHE_FILE, File::RDONLY|File::CREAT)) || []

#get existing episodes
existing_filenames = Dir.glob('*.mp4')
existing_eps_numbers = existing_filenames.map {|x| "/episodes/" + x[/\d+/].sub!(/^0*/, "") + "-"}

#get videos pages url from Railscasts pages
video_pages = get_video_pages(BASE_URL, [], video_page_cache)

#write back the cache
video_page_cache = video_pages | video_page_cache
File.open(VIDEO_PAGE_CACHE_FILE, 'w') do |f|
  f.write(video_page_cache.to_yaml)
end

#load each video pages, then download the video
download_videos(video_page_cache, existing_eps_numbers)

p 'Finished synchronization'
