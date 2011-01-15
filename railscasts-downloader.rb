#!/usr/bin/env ruby

###############################################################################
#
# RailsCasts Downloader 0.1
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

