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

#functions
def get_video_pages(page, video_pages, existing_eps_numbers, video_page_cache)
  cache_hit = false
  p "Reading #{page} ..."
  doc = Nokogiri::HTML(open(page))
  doc.search('//*[@href]').each do |m|
    episode = BASE_URL + m[:href] if m[:href].include?("episodes") && ! m[:href].include?("?")
    unless episode.nil? or existing_eps_numbers.any? { |eps| episode.include? eps } or video_pages.include?(episode)
      video_pages << episode
      cache_hit = video_page_cache.include? episode
    end
  end
  next_page_link = doc.search('//a[@class = "next_page"]')[0]
  if next_page_link and ! cache_hit
    video_pages = get_video_pages(BASE_URL + next_page_link[:href], video_pages, existing_eps_numbers, video_page_cache)
  end
  video_pages
end

def download_videos(video_pages)
  video_pages.each do |page|
    doc = Nokogiri::HTML(open(page))
    doc.search('//*[@href]').each do |m|
      video_url = m[:href] if m[:href].match ".mp4$"
      unless video_url.nil?
        filename = video_url.split('/').last

        p "Downloading #{filename}"
        %x(wget #{video_url} -c -O #{filename}.tmp )
        %x(mv #{filename}.tmp #{filename} )
        p "Finish downloading #{filename}"
      end
    end
  end
end

#load video page cache
video_page_cache = YAML::load(File.open(VIDEO_PAGE_CACHE_FILE, File::RDONLY|File::CREAT)) || []

#get existing episodes
existing_filenames = Dir.glob('*.mp4')
existing_eps_numbers = existing_filenames.map {|x| "/episodes/" + x[/\d+/].sub!(/^0*/, "") + "-"}

#get videos pages url from Railscasts pages
video_pages = get_video_pages(BASE_URL, [], existing_eps_numbers, video_page_cache)

#write back the cache
video_page_cache = video_pages | video_page_cache
File.open(VIDEO_PAGE_CACHE_FILE, 'w') do |f|
  f.write(video_page_cache.to_yaml)
end

#load each video pages, then download the video
#download_videos(video_pages)

p 'Finished synchronization'
