#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information
#++

require 'fileutils'
require 'pathname'
require 'tmpdir'
require 'yaml'

##
# MMS2R is a library to collect media files from MMS messages. MMS messages 
# are multipart emails and cellphone carriers often inject branding into these 
# messages. MMS2R strips the advertising from an MMS leaving the actual user 
# generated media.
#
# If you encounter MMS from a carrier that contains advertising and other non-
# standard media, submit a sample to the author for inclusion in this
# project.
#
# The create method is a factory method to create MMS2R::Media .
# Custom media producers can be pushed into the factory via the
# MMS2R::CARRIER_CLASSES Hash, e.g.
#
# class MMS2R::FakeCarrier < MMS2R::Media; end
# MMS2R::CARRIER_CLASSES['mms.fakecarrier.com'] = MMS2R::FakeCarrier
# ...
# media = MMS2R::Media.create(some_tmail) #media will be a MMS2R::FakeCarrier

module MMS2R

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
    # Various multi-parts that are bundled into mail

    MULTIPARTS_TO_SPLIT = [ 'multipart/related', 'multipart/alternative', 'multipart/mixed' ]

    ##
    # Factory method that creates MMS2R::Media products.
    #
    # Returns a MMS2R::Media product based on the characteristics
    # of the carrier from which the MMS originated.  
    # mail is a TMail object, logger is a Logger and can be
    # nil.

    def self.create(mail, logger=nil)
      d = lambda{['mms2r.media',MMS2R::Media]} #sets a default to detect
      cc = MMS2R::CARRIER_CLASSES.detect(d) do |n, c| 
        match = /[^@]+@(.+)/.match(mail.from[0].strip)
        # check for nil match -- usually a malformed message, but it's better 
        # not to choke on it.
        match && match[1] && (match[1].downcase == n.downcase)
      end
      cls = cc[1]
      cls.new(mail, cc[0], logger)
    end

    ##
    # Intialize a new Media comprised of a mail and
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
      # get warnings out of our hair ...
      @number = nil
      @subject = nil
      @body = nil
      @default_media = nil
      @default_text = nil

      #TODO: new should be 'create' refactor to this behavior
    end

    ##
    # Get the phone number associated with this MMS if it exists.
    # The value returned is simplistic it, is just the user name of
    # the from address before the @ symbol.  Validate the number by
    # your application on your own.  Most carriers are using the real
    # phone number as the username.

    def get_number
      # override this method in a child if the number exists elsewhere (like Sprint)
      @number ||= /^([^@]+)@/.match(mail.from[0])[1]
    end

    ##
    # Filter some common place holder subjects from MMS messages and
    # return nil such that default carrier subjects can be pragmatically
    # ignored.

    def get_subject

      return @subject if @subject # we've already done the work

      subject = @mail.subject
      return @subject ||= nil if subject.nil? || subject.strip.empty?

      # subject is not already set, lets see what our defaults are
      a = Array.new
      # default subjects to ignore are in mms2r_media.yml
      f = clz.yaml_file_name(sclz, :subject)
      yf = File.join(self.class.conf_dir(), "#{f}")
      a = a + YAML::load_file(yf) if File::exist?(yf) 
      # class default subjects
      f = clz.yaml_file_name(clz, :subject)
      yf = File.join(self.class.conf_dir(), "#{f}")
      a = a + YAML::load_file(yf) if File::exist?(yf) 
      return @subject ||= subject if a.empty?
      return @subject ||= nil if a.detect{|r| r.match(subject.strip)}
      return @subject ||= subject
    end
    
    # Convenience method that returns a string including all the text of the 
    # first text/plain file found. Returns empty string if no body text 
    # is found.
    def get_body
      return @body if @body

      text_file = get_text
      if text_file.nil?
        return @body ||= nil
      end
      
      return @body ||= IO.readlines(text_file.path).join.strip
    end

    # Returns a File with the most likely candidate for the user-submitted
    # media. Given that most MMS messages only have one file attached,
    # this will try to give you that file. First it looks for videos, then
    # images. It also adds singleton methods to the File object so it can
    # be used in place of a CGI upload (local_path, original_filename, size,
    # and content_type).  The largest file found in terms of bytes is returned.
    #
    # Returns nil if there are not any video or image Files found.

    def get_media
      return @default_media ||= get_attachement(['video', 'image'])
    end

    # Returns a File with the most likely candidate that is text, or nil
    # otherwise. It also adds singleton methods to the File object so it can
    # be used in place of a CGI upload (local_path, original_filename, size,
    # and content_type).  The largest file found in terms of bytes is returned.
    #
    # Returns nil if there are not any text Files found

    def get_text
      return @default_text ||= get_attachement(['text'])
    end

    ##
    # process is a template method and collects all the media in a MMS.
    # Override helper methods to this template to clean out advertising 
    # and/or ignore media that are advertising. This method should not be 
    # overridden unless there is an extreme special case in processing the 
    # media of a MMS (like Sprint)
    #
    # Helper methods for the process template:
    # * ignore_media? -- true if the media contained in a part should be ignored.
    # * process_media -- retrieves media to temporary file, returns path to file.
    # * transform_text -- called by process_media, strips out advertising.
    # * temp_file -- creates a temporary filepath based on information from the part.
    # 
    # Block support:
    # Calling process() with a block to automatically iterate through media.
    # For example, to process and receive all media types of video, you can do:
    #   mms.process do |media_type, file|
    #     results << file if media_type =~ /video/
    #   end
    #
    # note: purge must be explicitly called to remove the media files
    #       mms2r extracts from an mms message.

    def process() # :yields: media_type, file
      @logger.info("#{self.class} processing") unless @logger.nil?

      # build up all the parts
      parts = @mail.parts
      if !@mail.multipart?
        parts = Array.new()
        parts << @mail
      end

      # double check for multipart/related, if it exists
      # replace it with its children parts
      parts.each do |p|
        if MULTIPARTS_TO_SPLIT.include?(self.class.part_type?(p))
          part = parts.delete(p)
          part.parts.each { |mp| parts << mp }
        end
      end

      # multipart/related can have multipart/alternative as a child. if
      # exists, replace with children
      parts.each do |p|
        if self.class.part_type?(p).eql?('multipart/alternative')
          part = parts.delete(p)
          part.parts.each { |mp| parts << mp }
        end
      end

      # get to work
      parts.each do |p|
        t = self.class.part_type?(p)
        unless ignore_media?(t,p)
          t,f = process_media(p)
          add_file(t,f) unless t.nil? || f.nil?
        end
      end

      # when process acts upon a block
      if block_given?
        media.each do |k, v|
          yield(k, v)
        end
      end

    end

    ##
    # Helper for process template method to determine if 
    # media contained in a part should be ignored.  Producers 
    # should override this method to return true for media such 
    # as images that are advertising, carrier logos, etc.
    # The corresponding *_ignore.yml for a given class contains
    # either a regular expression for the text types or a file
    # name for all other types.  When writing an ignore regular
    # expression assume that the text it will be evaluated against
    # has been flattened where one or more consecutive whitespace 
    # (tab, space, new lines and line feeds) characters are replaced 
    # with one space ' ' character.

    def ignore_media?(type,part)

      # default media to ignore are in mms2r_media.yml
      # which is a hash of mime types as keys each to an
      # array of regular expressions
      f = clz.yaml_file_name(sclz, :ignore)
      yf = File.join(self.class.conf_dir(), "#{f}")
      h = YAML::load_file(yf) if File::exist?(yf) 
      h ||= Hash.new

      # merge in the ignore hash of the specific child
      f = clz.yaml_file_name(clz, :ignore)
      yf = File.join(self.class.conf_dir(), "#{f}")
      if File::exist?(yf)
        ignores = YAML::load_file(yf)
        ignores.each do |k,v|
          unless h[k]
            h[k] = v
          else
            v.each{|e| h[k] << e}
          end
        end
      end
      a ||= h[type]
      return false if h.empty? || a.nil?

      m = /^([^\/]+)\//.match(type)[1]
      # fire each regular expression, only break if there is a match
      ignore = a.each do |i|
        if m == 'text' || type == 'application/smil' || type == 'multipart/mixed'
          s = part.body.gsub(/\s+/m," ").strip
          break(i) if i.match(s)
        end
        break(i) if filename?(part).eql?(i)
      end
      return ignore.eql?(a) ? false : true # when ignore is equal to 'a' that
                                          # means none of the breaks fired in
                                          # the loop, if a break 
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
    # a normal mime part (like Sprint).
    #
    # Returns a tuple of content type, file path

    def process_media(part)
      # TMail body auto-magically decodes quoted
      # printable for text/html type.
      file = temp_file(part)
      case
      when self.class.main_type?(part).eql?('text')
        type, content = transform_text_part(part)
      when self.class.part_type?(part).eql?('application/smil')
        type, content = transform_text_part(part)
      else
        type = self.class.part_type?(part)
        content = part.body
      end
      return type, nil if content.nil?

      @logger.info("#{self.class} writing file #{file}") unless @logger.nil?
      File.open(file,'w'){ |f|
        f.write(content)
      }
      return type, file
    end

    ##
    # Helper for process_media template method to transform text.
    # The regular expressions for the transform are in the
    # conf/*_transform.yml files.
    # Input is the type of text and the text to transform.

    def transform_text(type, text)
      f = clz.yaml_file_name(clz, :transform)
      yf = File.join(self.class.conf_dir(), "#{f}")
      return type, text unless File::exist?(yf)

      h = YAML::load_file(yf)
      a = h[type]
      return type, text if a.nil?

      #convert to UTF-8
      begin
        c = Iconv.new('ISO-8859-1', 'UTF-8' )
        utf_t = c.iconv(text)
      rescue Exception => e
        utf_t = text
      end

      # 'from' is a Regexp in the conf and 'to' is the match position
      # or from is text that will be replaced with to
      a.each { |from,to| utf_t = utf_t.gsub(from,to).strip }
      return type, utf_t.strip
    end

    ##
    # Helper for process_media template method to transform text.
    # The regular expressions for the trans are in *_transform.yml
    # Input is a mail part

    def transform_text_part(part)
      type = self.class.part_type?(part)
      text = part.body.strip
      transform_text(type, text)
    end

    ##
    # Helper for process template method to name a temporary
    # filepath based on information in the part.  This version
    # attempts to honor the name of the media as labeled in the part
    # header and creates a unique temporary directory for writing
    # the file so filename collision does not occur.
    # Consumers of this method expect the directory
    # structure to the file exists, if the method is overridden it
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
    # Helper to add a file to the media hash.

    def add_file(type, file)
      @media[type] = [] unless @media[type]
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
    # returns a filename declared for a part, or a default if its not defined

    def filename?(part)
      part.sub_header("content-type", "name") ||
        part.sub_header("content-disposition", "filename") ||
        (part['content-location'] && part['content-location'].body) ||
        "#{Time.now.to_f}.#{self.class.default_ext(self.class.part_type?(part))}"
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
    # Helper to create a safe directory path element based on the
    # mail message id.

    def self.safe_message_id(mid)
      return "#{Time.now.to_i}" if mid.nil?
      mid.gsub(/\$|<|>|@|\./, "")
    end

    ##
    # Returns a default file extension based on a content type

    def self.default_ext(content_type)
      ext = MMS2R::EXT[content_type]
      ext = /[^\/]+\/(.+)/.match(content_type)[1] if ext.nil?
      ext
    end

    ##
    # Determines the mimetype of a part.  Guarantees a type is returned.

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

    ##
    # helper to contruct a yml file name with a class
    # name based pattern, i.e. mms2r_tmobilemedia_ignore.yml
    # for yaml_file_name(MMS2R::TMobileMedia,:ignore)

    def self.yaml_file_name(clz,kind)
      # like active_support's inflector
      flat = clz.name.gsub(/::/, '_').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z])([A-Z])/,'\1_\2').
      tr("-", "_").downcase
      "#{flat}_#{kind.to_s}.yml"
    end

    ##
    # helper to fetch self.class quicly

    def clz
      self.class
    end

    ##
    # helper to fetch self.class.superclass quickly

    def sclz
      self.class.superclass
    end

    private

    ##
    # used by get_media and get_text to return the biggest attachment type
    # listed in the types array

    def get_attachement(types)

      # get all the files that are of the major types passed in
      files = Array.new
      types.each do |t|
        media.keys.each do |k|
          files.concat(media[k]) if /^#{t}\//.match(k)
        end
      end
      return nil if files.empty?

      #get the largest file
      file = nil # explicitly declare the file and size
      size = 0
      mime_type = nil

      files.each do |f|
        # this will safely evaluate since we wouldn't be looking at
        # media[mime_type] after the check just before this
        if File.size(f) > size
          size = File.size(f)
          file = File.new(f)
          # media is hash of types to arrays of file names
          # detect on the hash returns an array, the 0th element is
          # the mime type of the file that was found in the files array
          # i.e. {'text/foo' => ['/foo/bar.txt', '/hello/world.txt']}
          mime_type = media.detect{|k,v| v.detect{|fl| fl == f}}[0] rescue nil
        end
      end

      # These singleton methods implement the interface necessary to be used
      # as a drop-in replacement for files uploaded with CGI.rb.
      # This helps if you want to use the files with, for example,
      # attachment_fu.

      def file.local_path
        self.path
      end

      def file.original_filename
        File.basename(self.path)
      end

      def file.size
        File.size(self.path)
      end

      # this one is kind of confusing because it needs a closure.
      class << file
        self
      end.send(:define_method, :content_type) { mime_type }

      file
    end

  end

end
