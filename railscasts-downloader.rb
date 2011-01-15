#!/usr/bin/env ruby

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
# Linking [name of your program] statically or dynamically with other modules
# is making a combined work based on [name of your program]. Thus, the terms
# and conditions of the GNU General Public License cover the whole combination.
#
# In addition, as a special exception, the copyright holders of [name of your
# program] give you permission to combine [name of your program] with free
# software programs or libraries that are released under the GNU LGPL and with
# code included in the standard release of [name of library] under the [name of
# library's license] (or modified versions of such code, with unchanged
# license). You may copy and distribute such a system following the terms of
# the GNU GPL for [name of your program] and the licenses of the other code
# concerned{, provided that you include the source code of that other code when
# and as the GNU GPL requires distribution of source code}.
#
# Note that people who make modified versions of [name of your program] are not
# obligated to grant this special exception for their modified versions; it is
# their choice whether to do so. The GNU General Public License gives
# permission to release a modified version without this exception; this
# exception also makes it possible to release a modified version which carries
# forward this exception.

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

