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
require 'net/http'
require 'open-uri'
require 'nokogiri'
require 'yaml'

#constants
BASE_URL = 'http://railscasts.com'
VIDEO_PAGE_CACHE_FILE = 'video_page_cache.yml'

#functions
def content_length(url)
  uri = URI.parse(url)
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request_head(uri.path) }
  response["content-length"].to_i
end

#load video page cache
video_page_cache = YAML::load(File.open(VIDEO_PAGE_CACHE_FILE, File::RDONLY|File::CREAT)) || []

mismatched_video = []

video_page_cache.each do |page|
  doc = Nokogiri::HTML(open(page))
  doc.search('//*[@href]').each do |m|
    video_url = m[:href] if m[:href].match ".mp4$"
    unless video_url.nil?
      filename = video_url.split('/').last
      length_in_server = content_length(video_url)
      length_in_local = File.size?(filename) || 0
      puts "Examining #{filename}, server: #{length_in_server} local: #{length_in_local}\n"
      unless length_in_server == length_in_local
        mismatched_video << filename
      end
    end
  end
end

unless mismatched_video.empty?
  puts "\nThe following video file have the size mismatched with the video on the server:\n"
  mismatched_video.each do |video_file|
    puts "#{video_file}\n"
  end
end
