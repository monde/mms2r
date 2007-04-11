# Copyright (c) 2007 by Mike Mondragon ()
#
# Please see the LICENSE file for licensing.

require 'fileutils'
require 'pathname'
require 'tmpdir'
require 'yaml'
require 'mms2r'
require 'mms2r/version'
require 'mms2r/cingular_media'
require 'mms2r/mmode_media'
require 'mms2r/nextel_media'
require 'mms2r/sprint_media'
require 'mms2r/tmobile_media'
require 'mms2r/verizon_media'

##
# MMS2R is a library to collect media files from MMS messages. MMS messages 
# are multipart emails and cellphone carriers often inject branding into these 
# messages. MMS2R strips the advertising from an MMS leaving the actual user 
# generated media.
#
# If you encounter MMS from a carrier that contains advertising other non-
# standard media features submit a sample to the author for inclusion in this
# project.
#
# The create method is a factory method to create MMS2R::Media
# Custom media producers can be pushed into the factory via the
# MMS2R::CARRIER_CLASSES Hash, e.g.
#
# class MMS2R::FakeCarrier < MMS2R::Media; end
# MMS2R::CARRIER_CLASSES['mms.fakecarrier.com'] = MMS2R::FakeCarrier
# ...
# media = MMS2R::Media.create(some_tmail) #media will be a MMS2R::FakeCarrier

module MMS2R

  ##
  # A hash of file extentions for common mimetypes
  EXT = {
    'text/plain' => 'txt',
    'text/html' => 'html',
    'image/png' => 'png',
    'image/gif' => 'gif',
    'image/jpeg' => 'jpg',
    'video/quicktime' => 'mov',
    'video/3gpp2' => '3g2'
  }

  ##
  # A hash of carriers that MMS2r is currently aware of.
  # The factory create method uses the hostname portion 
  # of an MMS's from to select the correct type of MMS2R::Media
  # product.  If a specific media product is not available
  # MMS2R::Media should be used.

  CARRIER_CLASSES = {
    'mms.mycingular.com' => MMS2R::CingularMedia,
    'cingularme.com' => MMS2R::CingularMedia,
    'mmode.com' => MMS2R::MModeMedia,
    'messaging.nextel.com' => MMS2R::NextelMedia,
    'pm.sprint.com' => MMS2R::SprintMedia,
    'messaging.sprintpcs.com' => MMS2R::SprintMedia,
    'tmomail.net' => MMS2R::TMobileMedia,
    'vtext.com' => MMS2R::VerizonMedia,
    'vzwpix.com' => MMS2R::VerizonMedia
  }

  class MMS2R::Media
    ##
    # TMail object that the media files were derived from.
    attr_reader :mail

    ##
    # media returns the hash of media.  The media hash
    # is keyed by mimetype such as 'text/plain' and the
    # value mapped to the key is an array of media that
    # are of that type.
    attr_reader :media

    ##
    # Carrier is the domain name of the carrier.  If the 
    # carrier is not known the carrier will be set to 'mms2r.media'

    attr_reader :carrier

    ##
    # Base working dir where media for a unique mms message are
    # dropped

    attr_reader :media_dir

    ##
    # Creates a new Media comprised of a mail
    # a logger.  Logger is an instance attribute allowing
    # for a logging strategy per carrier type

    def initialize(mail, carrier, logger=nil)
      @mail = mail
      @carrier = carrier
      @logger = logger
      @logger.info("#{self.class} created") unless @logger.nil?
      @media = Hash.new
      @dir_count = 0
      @media_dir = File.join(self.class.tmp_dir(), 
                     self.class.safe_message_id(@mail.message_id))
    end

    ##
    # Helper for process template method to decode the part based 
    # on its type and write its content to a temporary file.  Returns 
    # path to temporary file that holds the content.  Parts with a main
    # type of text will have their contents transformed with a call to
    # transform_text
    #
    # Producers should only override this method if the parts of
    # the MMS need special treatment besides what is expected for
    # a normal mime part.
    #
    # Returns a tupple of content type, file path

    def process_media(part)
      # TMail body auto-magically decodes quoted
      # printable for text/html type.
      file = temp_file(part)
      if self.class.main_type?(part).eql?('text')
        type, content = transform_text(part)
      else
        type = self.class.part_type?(part)
        content = part.body
      end
      @logger.info("#{self.class} writing file #{file}") unless @logger.nil?
      File.open(file,'w'){ |f|
        f.write(content)
      }
      return type, file
    end

    ##
    # Helper for process_media template method to transform text.

    def transform_text(part)
      type = self.class.part_type?(part)
      text = part.body
      f = "#{self.class.name.downcase.gsub(/::/,'_')}_transform.yml"
      yf = File.join(self.class.conf_dir(), "#{f}")
      return type, text unless File::exist?(yf)
      h = YAML::load_file(yf)
      a = h[type]
      return type, text if a.nil?
      a.each do |from,to|
        text.gsub!(/#{from}/m,to)
      end
      return type, text
    end

    ##
    # Helper for process template method to determine if 
    # media contained in a part should be ignored.  Producers 
    # should override this method to return true for media such 
    # as images that are advertising, carrier logos, etc.

    def ignore_media?(type,part)
      f = "#{self.class.name.downcase.gsub(/::/,'_')}_ignore.yml"
      yf = File.join(self.class.conf_dir(), "#{f}")
      return false unless File::exist?(yf)
      h = YAML::load_file(yf)
      a = h[type]
      return false if a.nil?
      m = /^([^\/]+)\//.match(type)[1]
      a.each do |i|
        if m.eql?('text')
          return true if 0 == (part.body =~ /#{Regexp.escape("#{i}")}/m)
        else
          return true if filename?(part).eql?(i)
        end
      end
      false
    end

    ##
    # Helper for process template method to name a temporary
    # filepath based on information in the part.  This version
    # attempts to honor the name of the media as labeled in the part
    # header and creates a unique temporary directory for writing
    # the file so filename collision does not occur.
    # Consumers of this method expect the directory
    # structure to the file exists, if the method is overriden it
    # is mandatory that this behavior is retained.

    def temp_file(part)
      file_name = filename?(part)
      File.join(msg_tmp_dir(),File.basename(file_name))
    end

    ##
    # Purges the unique MMS2R::Media.media_dir directory created 
    # for this producer and all of the media that it contains.

    def purge()
      @logger.info("#{self.class} purging #{@media_dir} and all its contents") unless @logger.nil?
      FileUtils.rm_rf(@media_dir)
    end

    ##
    # process is a template method and collects all the media in a MMS.
    # Override helper methods to this template to clean out advertising 
    # and/or ignore media that are advertising. This method should not be 
    # overridden unless there is an extreme special case in processing the 
    # media of a MMS.
    #
    # Helpers methods for the process template:
    # * ignore_media? -- true if the media contained in a part should be ignored.
    # * process_media -- retrieves media to temporary file, returns path to file.
    # * transform_text -- called by process_media, strips out advertising.
    # * temp_file -- creates a temporary filepath based on information from the part.

    def process()
      @logger.info("#{self.class} processing") unless @logger.nil?

      parts = @mail.parts
      if !@mail.multipart?
        parts = Array.new()
        parts << @mail
      end
      parts.each do |p|
        if self.class.part_type?(p).eql?('multipart/alternative')
          part = parts.delete(p)
          part.parts.each do |mp|
             parts << mp
          end
        end
      end
      parts.each do |p|
        t = self.class.part_type?(p)
        unless ignore_media?(t,p)
          t,f = process_media(p)
          add_file(t,f) unless f.nil?
        end
      end
    end

    ##
    # Helper to add a file to the media hash.

    def add_file(type, file)
      if @media[type].nil?
        @media[type] = Array.new
      end
      @media[type] << file
    end

    ##
    # Helper to temp_file to create a unique temporary directory that is
    # a child of tmp_dir  This version is based on the message_id of the
    # mail.

    def msg_tmp_dir()
      @dir_count += 1
      dir = File.join(@media_dir, "#{@dir_count}")
      FileUtils.mkdir_p(dir)
      dir
    end

    ##
    # Factory method that creates MMS2R::Media products.
    #
    # Returns a MMS2R::Media product based on the characteristics
    # of the carrier from which the the MMS originated.  
    # mail is a TMail object, logger is a Logger and can be
    # nil.

    def self.create(mail, logger=nil)
      d = lambda{['mms2r.media',MMS2R::Media]}
      cc = MMS2R::CARRIER_CLASSES.detect(d) do |n, c| 
              /[^@]+@(.+)/.match(mail.from[0])[1] =~ /#{Regexp.escape("#{n}")}/
      end
      cls = cc[1]
      cls.new(mail, cc[0], logger)
    end

    ##
    # returns a filename declared for a part, or a default if its not defined

    def filename?(part)
      part.sub_header("content-type", "name") ||
        part.sub_header("content-disposition", "filename") ||
        (part['content-location'] && part['content-location'].body) ||
        "#{Time.now.to_i}.#{self.class.default_ext(self.class.part_type?(part))}"
    end

    @@tmp_dir = File.join(Dir.tmpdir, (ENV['USER'].nil? ? '':ENV['USER']), 'mms2r')

    ##
    # Get the temporary directory where media files are written to.

    def self.tmp_dir
      @@tmp_dir
    end

    ##
    # Set the temporary directory where media files are written to.
    def self.tmp_dir=(d)
      @@tmp_dir=d
    end

    @@conf_dir = File.join(File.dirname(__FILE__), '..', '..', 'conf')

    ##
    # Get the directory where conf files are stored.

    def self.conf_dir
      @@conf_dir
    end

    ##
    # Set the directory where conf files are stored.
    def self.conf_dir=(d)
      @@conf_dir=d
    end

    ##
    # Helper to created a safe directory path element based on the
    # mail message id.

    def self.safe_message_id(mid)
      return "#{Time.now.to_i}" if mid.nil?
      mid.gsub(/\$|<|>|@|\./, "")
    end

    ##
    # Returns a default file extension based on a content_type

    def self.default_ext(content_type)
      ext = MMS2R::EXT[content_type]
      return /[^\/]+\/(.+)/.match(content_type)[1] if ext.nil?
      ext
    end

    ##
    # Determines the mimetype of a part.  Gauruntees a type is returned.

    def self.part_type?(part)
      if part.content_type.nil?
        return 'text/plain'
      end
      part.content_type
    end

    ##
    # Determines the main type of the part's mimetype

    def self.main_type?(part)
      /^([^\/]+)\//.match(self.part_type?(part))[1]
    end

    ##
    # Determines the sub type of the part's mimetype

    def self.sub_type?(part)
      /\/([^\/]+)$/.match(self.part_type?(part))[1]
    end

  end

end
