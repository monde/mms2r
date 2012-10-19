#--
# Copyright (c) 2007-2012 by Mike Mondragon (mikemondragon@gmail.com)
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
    # Spoof User-Agent, primarily for the Sprint CDN

    USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.120 Safari/535.2"
  end

  ##
  # Simple convenience function to make it a one-liner:
  # MMS2R.parse raw_mail or
  # MMS2R.parse File.load(file)
  # MMS2R.parse File.load(path_to_file)
  # Combined w/ the method_missing delegation, this should behave as an enhanced Mail object, more or less.

  def self.parse thing, options = {}
    mail = case
           when File.exist?(thing); Mail.new(open(thing).read)
           when thing.respond_to?(:read); Mail.new(thing.read)
           else
             Mail.new(thing)
           end

    MMS2R::Media.new(mail, options)
  end

  ##
  # Compare original MMS2R results with original mail values and other metrics.
  #
  # Takes a file path, mms2r object, mail object, or mail text blob.

  def self.debug(thing, options = {})
    mms = case thing
          when MMS2R::Media; thing
          when Mail::Message; MMS2R::Media.new(thing, options)
          else
            self.parse(thing, options)
          end

    <<OUT
#{'-' * 80}

  original mail
    #{'from:'.ljust(15)} #{mms.mail.from}
    #{'to:'.ljust(15)} #{mms.mail.to}
    #{'subject:'.ljust(15)} #{mms.mail.subject}

  mms2r
    #{'from:'.ljust(15)} #{mms.from}
    #{'to:'.ljust(15)} #{mms.to}
    #{'subject:'.ljust(15)} #{mms.subject}
    #{'number:'.ljust(15)} #{mms.number}

    default media
      #{mms.default_media.inspect}

    default text
      #{mms.default_text.inspect}
      #{mms.default_text.read if mms.default_text}

    all plain text
      #{(mms.media['text/plain']||[]).each {|t| open(t).read}.join("\n\n")}

    media hash
      #{mms.media.inspect}

OUT
  end

end

%W{ yaml mail fileutils pathname tmpdir yaml digest/sha1 exifr }.each do |g|
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
