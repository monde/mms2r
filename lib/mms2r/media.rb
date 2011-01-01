#--
# Copyright (c) 2007-2010 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information.
#++

##
# = Synopsis
#
# MMS2R is a library to collect media files from MMS messages.  MMS messages
# are multipart emails and mobile carriers often inject branding into these
# messages.  MMS2R strips the advertising from an MMS leaving the actual user
# generated media.
#
# The Tracker for MMS2R is located at
# http://rubyforge.org/tracker/?group_id=3065
# Please submit bugs and feature requests using the Tracker.
#
# If MMS from a carrier not known by MMS2R is encountered please submit a
# sample to the author for inclusion in this project.
#
# == Stand Alone Example
#
#  begin
#    require 'mms2r'
#  rescue LoadError
#    require 'rubygems'
#    require 'mms2r'
#  end
#  mail = Mail.read("sample-MMS.file")
#  mms = MMS2R::Media.new(mail)
#  subject = mms.subject
#  number = mms.number
#  file = mms.default_media
#  mms.purge
#
# == Rails ActionMailer#receive w/ AttachmentFu Example
#
#  def receive(mail)
#    mms = MMS2R::Media.new(mail)
#    picture = Picture.new # picture is an attachemnt_fu model
#    picture.title = mms.subject
#    picture.uploaded_data = mms.default_media
#    picture.save!
#    mms.purge
#  end
#
# == More Examples
#
# See the README.txt file for more examples
#
# == Built In Configuration
#
# A custom configuration can be created for processing the MMS from carriers
# that are not currently known by MMS2R.  In the  conf/ directory create a
# YAML file named by combining the domain name of the MMS sender plus a .yml
# extension.  For instance the configuration of senders from AT&T's cellular
# service with a Sender pattern of 2065551212@mms.att.net have a configuration
# named conf/mms.att.net.yml
#
# The YAML configuration contains a Hash with instructions for determining what
# is content generated by the user and what is content inserted by the carrier.
#
# The root hash itself has two hashes under the keys 'ignore' and 'transform',
# and an array under the 'number' key.
# Each hash is itself keyed by mime-type.  The value pointed to by the mime-type
# key is an array.  The ignore arrays are first evaluated as a regular expressions
# and if the evaluation fails as a equality for a string filename.  Ignores
# work by filename for the multi-part of the MMS that is being inspected.  The
# array pointed to by the 'number' key represents an alternate mail header where
# the sender's number can be found with a regular expression and replacement
# value for a gsub eval.
#
# The transform arrays are themselves an array of two element arrays.  The elements
# are parameters for gsub and will be evaluated from within the ruby code.
#
# Ignore instructions are honored first then transform instructions.  In the sample,
# masthead.jpg is ignored as a regular expression, and spacer.gif is ignored as a
# filename comparison.  The transform has a match and a replacement, see the gsub
# documentation for more information about match and replace.
#
# --
# ignore:
#   image/jpeg:
#   - /^masthead.jpg$/i
#   image/gif:
#   - spacer.gif
#   text/plain:
#   - /\AThis message was sent using PIX-FLIX Messaging service from .*/m
# transform:
#   text/plain:
#   - - /\A(.+?)\s+This message was sent using PIX-FLIX Messaging .*/m
#     - "\1"
# number:
#   - from
#   - /^([^\s]+)\s.*/
#   - "\1"
#
# Carriers often provide their services under many different domain names.
# The conf/aliases.yml is a YAML file with a hash that maps alternative or
# legacy carrier names to the most common name of their service.  For example
# in terms of MMS2R txt.att.net is an alias for mms.att.net.  Therefore when
# an MMS with a Sender of txt.att.net is processed MMS2R will use the
# mms.att.net configuration to process the message.

module MMS2R

  class MMS2R::Media

    # Pass off everything we don't do to the Mail object
    # TODO: refactor to explicit addition a la http://blog.jayfields.com/2008/02/ruby-replace-methodmissing-with-dynamic.html
    def method_missing method, *args, &block
      mail.send method, *args, &block
    end

    ##
    # Mail object that the media files were derived from.

    attr_reader :mail

    ##
    # media returns the hash of media.  The media hash is keyed by mime-type
    # such as 'text/plain' and the value mapped to the key is an array of
    # media that are of that type.

    attr_reader :media

    ##
    # Carrier is the domain name of the carrier.  If the carrier is not known
    # the carrier will be set to 'mms2r.media'

    attr_reader :carrier

    ##
    # Base working dir where media for a unique mms message are dropped

    attr_reader :media_dir

    ##
    # Determine if return-path or from is going to be used to desiginate the
    # origin carrier.  If the domain in the From header is listed in
    # conf/from.yaml then that is the carrier domain.  Else if there is a
    # Return-Path header its address's domain is the carrier doamin, else
    # use From header's address domain.

    def self.domain(mail)
      return_path = case
        when mail.return_path
          mail.return_path ? mail.return_path.split('@').last : ''
        else
          ''
        end

      from_domain = case
        when mail.from && mail.from.first
          mail.from.first.split('@').last
        else
          ''
        end

      f = File.expand_path(File.join(self.conf_dir(), "from.yml"))
      from = YAML::load_file(f) rescue {}

      ret = case
        when from.include?(from_domain)
          from_domain
        when return_path.present?
          return_path
        else
          from_domain
        end
      ret
    end


    ##
    # Initialize a new MMS2R::Media comprised of a mail.
    #
    # Specify options to initialize with:
    # :logger => some_logger for logging
    # :process => :lazy, for non-greedy processing upon initialization
    #
    # #process will have to be called explicitly if the lazy process option
    # is chosen.

    def initialize(mail, opts={})

      @mail = mail
      @logger = opts[:logger]
      log("#{self.class} created", :info)
      @carrier = self.class.domain(mail)
      @dir_count = 0
      @media_dir = File.expand_path(
                     File.join(self.tmp_dir(),
                     "#{self.safe_message_id(@mail.message_id)}_#{UUIDTools::UUID.random_create}"))
      @media = {}
      @was_processed = false
      @number = nil
      @subject = nil
      @body = nil
      @exif = nil
      @default_media = nil
      @default_text = nil
      @default_html = nil

      f = File.expand_path(File.join(self.conf_dir(), "aliases.yml"))
      @aliases = YAML::load_file(f) rescue {}

      conf = "#{@aliases[@carrier] || @carrier}.yml"
      f = File.expand_path(File.join(self.conf_dir(), conf))
      c = YAML::load_file(f) rescue {}
      @config = self.class.initialize_config(c)

      processor_module = MMS2R::CARRIERS[@carrier]
      extend processor_module if processor_module

      lazy = (opts[:process] == :lazy) rescue false
      self.process() unless lazy
    end

    ##
    # Get the phone number associated with this MMS if it exists.  The value
    # returned is simplistic, it is just the user name of the from address
    # before the @ symbol.  Validation of the number is left to you.  Most
    # carriers are using the real phone number as the username.

    def number
      unless @number
        params = config['number']
        if params && params.any? && (header = mail.header[params[0]])
          @number = header.to_s.gsub(eval(params[1]), params[2])
        end
        if @number.nil? || @number.blank?
          @number = mail.from.first.split(/@|\//).first rescue ""
        end
      end

      @number
    end

    ##
    # Return the Subject for this message, returns "" for default carrier
    # subject such as 'Multimedia message' for ATT&T carrier.

    def subject

      unless @subject
        subject = mail.subject.strip rescue ""
        ignores = config['ignore']['text/plain']
        if ignores && ignores.detect{|s| s == subject}
          @subject = ""
        else
          @subject = transform_text('text/plain', subject).last
        end
      end

      @subject
    end

    # Convenience method that returns a string including all the text of the
    # default text/plain file found.  If the plain text is blank then it returns
    # stripped down version of the title and body of default text/html.  Returns
    # empty string if no body text is found.

    def body
      text_file = default_text
      @body = text_file ? IO.readlines(text_file.path).join.strip : ""
      if @body.blank? && html_file = default_html
        html = Nokogiri::HTML(IO.read(html_file.path))
        @body = (html.xpath("//head/title").map(&:text) + html.xpath("//body/*").map(&:text)).join(" ")
      end
      @body
    end

    # Returns a File with the most likely candidate for the user-submitted
    # media.  Given that most MMS messages only have one file attached, this
    # method will try to return that file.  Singleton methods are added to
    # the File object so it can be used in place of a CGI upload (local_path,
    # original_filename, size, and content_type) such as in conjunction with
    # AttachementFu.  The largest file found in terms of bytes is returned.
    #
    # Returns nil if there are not any video or image Files found.

    def default_media
      @default_media ||= attachment(['video', 'image', 'application', 'text'])
    end

    # Returns a File with the most likely candidate that is text, or nil
    # otherwise.  It also adds singleton methods to the File object so it can be
    # used in place of a CGI upload (local_path, original_filename, size, and
    # content_type) such as in conjunction with AttachmentFu.  The largest file
    # found in terms of bytes is returned.
    #
    # Returns nil if there are not any text Files found

    def default_text
      @default_text ||= attachment(['text/plain'])
    end

    # Returns a File with the most likely candidate that is html, or nil
    # otherwise.  It also adds singleton methods to the File object so it can be
    # used in place of a CGI upload (local_path, original_filename, size, and
    # content_type) such as in conjunction with AttachmentFu.  The largest file
    # found in terms of bytes is returned.
    #
    # Returns nil if there are not any text Files found

    def default_html
      @default_html ||= attachment(['text/html'])
    end

    ##
    # process is a template method and collects all the media in a MMS.
    # Override helper methods to this template to clean out advertising and/or
    # ignore media that are advertising.  This method should not be overridden
    # unless there is an extreme special case in processing the media of a MMS
    # (like Sprint)
    #
    # Helper methods for the process template:
    # * ignore_media? -- true if the media contained in a part should be ignored.
    # * process_media -- retrieves media to temporary file, returns path to file.
    # * transform_text -- called by process_media, strips out advertising.
    # * temp_file -- creates a temporary filepath based on information from the part.
    #
    # Block support:
    # Call process() with a block to automatically iterate through media.
    # For example, to process and receive only media of video type:
    #   mms.process do |media_type, file|
    #     results << file if media_type =~ /video/
    #   end
    #
    # note: purge must be explicitly called to remove the media files
    #       mms2r extracts from an mms message.

    def process() # :yields: media_type, file
      unless @was_processed
        log("#{self.class} processing", :info)

        parts = mail.multipart? ? mail.parts : [mail]

        # Double check for multipart/related, if it exists replace it with its
        # children parts.  Do this twice as multipart/alternative can have
        # children and we want to fold everything down
        for i in 1..2
          flat = []
          parts.each do |p|
            if p.multipart?
              p.parts.each {|mp| flat << mp }
            else
              flat << p
            end
          end
          parts = flat.dup
        end

        # get to work
        parts.each do |p|
          t = p.part_type?
          unless ignore_media?(t,p)
            t,f = process_media(p)
            add_file(t,f) unless t.nil? || f.nil?
          end
        end

        @was_processed = true
      end

      # when process acts upon a block
      if block_given?
        media.each do |k, v|
          yield(k, v)
        end
      end

    end

    ##
    # Helper for process template method to determine if media contained in a
    # part should be ignored.  Producers should override this method to return
    # true for media such as images that are advertising, carrier logos, etc.
    # See the ignore section in the discussion of the built-in configuration.

    def ignore_media?(type, part)
      ignores = config['ignore'][type] || []
      ignore   = ignores.detect{ |test| filename?(part) == test}
      ignore ||= ignores.detect{ |test| filename?(part) =~ eval(test) if test.index('/') == 0 }
      ignore ||= ignores.detect{ |test| part.body.decoded.strip =~ eval(test) if test.index('/') == 0 }
      ignore ||= (part.body.decoded.strip.size == 0 ? true : nil)
      ignore.nil? ? false : true
    end

    ##
    # Helper for process template method to decode the part based on its type
    # and write its content to a temporary file.  Returns path to temporary
    # file that holds the content.  Parts with a main type of text will have
    # their contents transformed with a call to transform_text
    #
    # Producers should only override this method if the parts of the MMS need
    # special treatment besides what is expected for a normal mime part (like
    # Sprint).
    #
    # Returns a tuple of content type, file path

    def process_media(part)
      # Mail body auto-magically decodes quoted
      # printable for text/html type.
      file = temp_file(part)
      if part.part_type? =~ /^text\// ||
         part.part_type? == 'application/smil'
        type, content = transform_text_part(part)
        mode = 'w'
      else
        if part.part_type? == 'application/octet-stream'
          type = type_from_filename(filename?(part))
        else
          type = part.part_type?
        end
        content = part.body.decoded
        mode = 'wb' # open with binary bit for Windows for non text
      end
      return type, nil if content.nil? || content.empty?

      log("#{self.class} writing file #{file}", :info)
      File.open(file, mode){ |f| f.write(content) }
      return type, file
    end

    ##
    # Helper for process_media template method to transform text.
    # See the transform section in the discussion of the built-in
    # configuration.

    def transform_text(type, text, original_encoding = 'ISO-8859-1')

      return type, text if !config['transform'] || !(transforms = config['transform'][type])

      #convert to UTF-8
      begin
        c = Iconv.new('UTF-8', original_encoding )
        utf_t = c.iconv(text)
      rescue Exception => e
        utf_t = text
      end

      transforms.each do |transform|
        next unless transform.size == 2
        p = transform.first
        r = transform.last
        utf_t = utf_t.gsub(eval(p), r) rescue utf_t
      end

      return type, utf_t
    end

    ##
    # Helper for process_media template method to transform text.

    def transform_text_part(part)
      type = part.part_type?
      text = part.body.decoded.strip
      transform_text(type, text)
    end

    ##
    # Helper for process template method to name a temporary filepath based on
    # information in the part.  This version attempts to honor the name of the
    # media as labeled in the part header and creates a unique temporary
    # directory for writing the file so filename collision does not occur.
    # Consumers of this method expect the directory structure to the file
    # exists, if the method is overridden it is mandatory that this behavior is
    # retained.

    def temp_file(part)
      file_name = filename?(part)
      File.expand_path(File.join(msg_tmp_dir(),File.basename(file_name)))
    end

    ##
    # Purges the unique MMS2R::Media.media_dir directory created
    # for this producer and all of the media that it contains.

    def purge()
      log("#{self.class} purging #{@media_dir} and all its contents", :info)
      FileUtils.rm_rf(@media_dir)
    end

    ##
    # Helper to add a file to the media hash.

    def add_file(type, file)
      media[type] = [] unless media[type]
      media[type] << file
    end

    ##
    # Helper to temp_file to create a unique temporary directory that is a
    # child of tmp_dir  This version is based on the message_id of the mail.

    def msg_tmp_dir()
      @dir_count += 1
      dir = File.expand_path(File.join(@media_dir, "#{@dir_count}"))
      FileUtils.mkdir_p(dir)
      dir
    end

    ##
    # returns a filename declared for a part, or a default if its not defined

    def filename?(part)
      name = part.filename
      if (name.nil? || name.empty?)
        if part.content_id && part.content_id.strip =~ /^<(.+)>$/
          name = $1
        else
          name = "#{Time.now.to_f}.#{self.default_ext(part.part_type?)}"
        end
      end
      # XXX fwiw, janky look for dot extension 1 to 4 chars long
      name = (name =~ /\..{1,4}$/ ? name : "#{name}.#{self.default_ext(part.part_type?)}").strip

      # handle excessively large filenames
      if name.size > 255
        ext = File.extname(name)
        base = File.basename(name, ext)
        name = "#{base[0, 255 - ext.size]}#{ext}"
      end

      name
    end

    def aliases
      @aliases
    end

    ##
    # Best guess of the mobile device type.  Simple heuristics thus far by 
    # inspecting mail headers and jpeg/tiff exif metadata.
    # Smart phone types are
    # :iphone :blackberry :dash :droid
    # If the message is from a carrier known to MMS2R, and not a smart phone
    # its type is returned as :handset
    # Otherwise device type is :unknown

    def device_type?

      file = attachment(['image'])
      if file
        original = file.original_filename
        @exif = case original
                when /\.je?pg$/i
                  EXIFR::JPEG.new(file)
                when /\.tiff?$/i
                  EXIFR::TIFF.new(file)
                end
        if @exif
          models = config['device_types']['models'] rescue {}
          models.each do |model, regex|
            return model if @exif.model =~ regex
          end
          makes = config['device_types']['makes'] rescue {}
          makes.each do |make, regex|
            return make if @exif.make =~ regex
          end
        end
      end

      headers = config['device_types']['headers'] rescue {}
      headers.keys.each do |header|
        if mail.header[header.downcase]
          # headers[header] refers to a hash of smart phone types with regex values
          # that if they match, the header signals the type should be returned
          headers[header].each do |type, regex|
            return type if mail.header[header.downcase].decoded =~ regex
          end
        end
      end

      return :handset if File.exist?( File.expand_path(
                             File.join(self.conf_dir, "#{self.aliases[self.carrier] || self.carrier}.yml")
                         ) )

      :unknown
    end

    ##
    # exif object on default image from exifr gem

    def exif
      device_type? unless @exif
      @exif
    end

    ##
    # The source of the MMS was some sort of mobile or smart phone

    def is_mobile?
      self.device_type? != :unknown
    end

    ##
    # Get the temporary directory where media files are written to.

    def self.tmp_dir
      @@tmp_dir ||= File.expand_path(File.join(Dir.tmpdir, (ENV['USER'].nil? ? '':ENV['USER']), 'mms2r'))
    end

    ##
    # Set the temporary directory where media files are written to.
    def self.tmp_dir=(d)
      @@tmp_dir=d
    end

    ##
    # Get the directory where conf files are stored.

    def self.conf_dir
      @@conf_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'conf'))
    end

    ##
    # Set the directory where conf files are stored.

    def self.conf_dir=(d)
      @@conf_dir=d
    end

    ##
    # Helper to create a safe directory path element based on the mail message
    # id.

    def self.safe_message_id(mid)
      mid.nil? ? "#{Time.now.to_i}" : mid.gsub(/\$|<|>|@|\./, "")
    end

    ##
    # Returns a default file extension based on a content type

    def self.default_ext(content_type)
      if MMS2R::EXT[content_type]
        MMS2R::EXT[content_type]
      elsif content_type
        content_type.split('/').last
      end
    end

    ##
    # Joins the generic mms2r configuration with the carrier specific
    # configuration.

    def self.initialize_config(c)
      f = File.expand_path(File.join(self.conf_dir(), "mms2r_media.yml"))
      conf = YAML::load_file(f) rescue {}
      conf['ignore'] ||= {} unless conf['ignore']
      conf['transform'] = {} unless conf['transform']
      conf['number'] = [] unless conf['number']
      return conf unless c

      kinds = ['ignore', 'transform']

      kinds.each do |kind|
        if c[kind]
          c[kind].each do |type,array|
            conf[kind][type] = [] unless conf[kind][type]
            conf[kind][type] += array
          end
        end
      end
      conf['number'] = c['number'] if c['number']

      conf
    end

    def log(message, level = :info)
      @logger.send(level, message) unless @logger.nil?
    end

    ##
    # convenience accessor for self.class.conf_dir

    def conf_dir
      self.class.conf_dir
    end

    ##
    # convenience accessor for self.class.conf_dir

    def tmp_dir
      self.class.tmp_dir
    end

    ##
    # convenience accessor for self.class.default_ext

    def default_ext(type)
      self.class.default_ext(type)
    end

    ##
    # convenience accessor for self.class.safe_message_id

    def safe_message_id(message_id)
      self.class.safe_message_id(message_id)
    end

    ##
    # convenience accessor for self.class.initialize_confg

    def initialize_config(config)
      self.class.initialize_config(config)
    end

    private

    ##
    # accessor for the config

    def config
      @config
    end

    ##
    # guess content type from filename

    def type_from_filename(filename)
      ext = filename.split('.').last
      ent = MMS2R::EXT.detect{|k,v| v == ext}
      ent.nil? ? nil : ent.first
    end

    ##
    # used by #default_media and #text to return the biggest attachment type
    # listed in the types array

    def attachment(types)

      # get all the files that are of the major types passed in
      files = []

      types.each do |type|
        media.keys.find_all{|k| type.include?("/") ? k == type : k.index(type) == 0 }.each do |key|
          files += media[key]
        end
      end
      return nil if files.empty?

      # set temp holders
      file = nil # explicitly declare the file and size
      size = 0
      mime_type = nil

      #get the largest file
      files.each do |path|
        if File.size(path) > size
          size = File.size(path)
          file = File.new(path)
          media.each do |type,files|
            mime_type = type if files.detect{ |_path| _path == path }
          end
        end
      end

      return nil if file.nil?

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
