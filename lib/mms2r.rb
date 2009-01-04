#--
# Copyright (c) 2007, 2008 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information.
#++

module MMS2R

  ##
  # A hash of MMS2R processors keyed by MMS carrier domain.

  CARRIERS = {}
  
  ##
  # Registers a class as a processor for a MMS domain.  Should only be 
  # used in special cases such as MMS2R::Media::Sprint for 'pm.sprint.com'

  def self.register(domain, processor_class)
    MMS2R::CARRIERS[domain] = processor_class
  end

  ##
  # A hash of file extensions for common mime-types

  EXT = {
    'text/plain' => 'text',
    'text/plain' => 'txt',
    'text/html' => 'html',
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/jpeg' => 'jpeg',
    'image/jpeg' => 'jpg',
    'video/quicktime' => 'mov',
    'video/3gpp2' => '3g2'
  }

  class MMS2R::Media

    ##
    # MMS2R library version

    VERSION = '2.2.0'

  end

end

require 'rubygems'
gem 'tmail', '>= 1.2.3'
require 'tmail/mail'
require 'fileutils'
require 'pathname'
require 'tmpdir'
require 'yaml'

require File.join(File.dirname(__FILE__), 'tmail_ext')
require File.join(File.dirname(__FILE__), 'mms2r', 'media')
require File.join(File.dirname(__FILE__), 'mms2r', 'media', 'sprint')
MMS2R.register('pm.sprint.com', MMS2R::Media::Sprint)
