#--
# Copyright (c) 2007-2010 by Mike Mondragon (mikemondragon@gmail.com)
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

    VERSION = '3.6.2'

    ##
    # Spoof User-Agent, primarily for the Sprint CDN

    USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.120 Safari/535.2"
  end

  # Simple convenience function to make it a one-liner:
  # MMS2R.parse raw_mail or MMS2R.parse File.load(raw_mail)
  # Combined w/ the method_missing delegation, this should behave as an enhanced Mail object, more or less.
  def self.parse raw_mail, options = {}
    mail = Mail.new raw_mail
    MMS2R::Media.new(mail, options)
  end

end

%W{ yaml mail fileutils pathname tmpdir yaml digest/sha1 iconv exifr }.each do |g|
  begin
    require g
  rescue LoadError
    require 'rubygems'
    require g
  end
end

if RUBY_VERSION >= "1.9"
  begin
    require 'psych'
    YAML::ENGINE.yamler= 'syck' if defined?(YAML::ENGINE)
  rescue LoadError
  end
end


require File.join(File.dirname(__FILE__), 'ext/mail')
require File.join(File.dirname(__FILE__), 'ext/object')
require File.join(File.dirname(__FILE__), 'mms2r/media')
require File.join(File.dirname(__FILE__), 'mms2r/media/sprint')

MMS2R.register('pm.sprint.com', MMS2R::Media::Sprint)
