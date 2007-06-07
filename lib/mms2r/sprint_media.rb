require 'net/http'
require 'rubygems'
require 'hpricot'
require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Sprint version of MMS2R::Media
  #
  # Sprint is an annoying carrier because they think they
  # are so important that they don't actually transmit
  # user generated content (like images or videos) directly 
  # in the MMS message.  Instead, what they do is hijack the 
  # media that is sent from the cellular subscriber and place 
  # that content on a content server.  In place of the media 
  # the recipient receives a HTML part telling the recipient 
  # how great Sprint is with links back to their content server.
  # Then the recipient has to click through Sprint more pages 
  # to view the content.
  #
  # The default subject on these messages from the
  # carrier is "You have new Picture Mail!"

  class MMS2R::SprintMedia < MMS2R::Media

    ##
    # MMS2R::SprintMedia has to override process() because Sprint
    # doesn't attach media (images, video, etc.) to its MMS.  Media such
    # as images and videos are hosted on a Sprint content server. 
    # MMS2R::SprintMedia has to pick apart an HTML attachment to find
    # the URL to the media on Sprint's content server and download
    # each piece of content.  Any text message part of the MMS 
    # if it exists is embedded in the html.

    def process
      @logger.info("#{self.class} processing") unless @logger.nil?
      #sprint MMS are multipart
      parts = @mail.parts

      #find the payload html
      doc = nil
      parts.each do |p|
        next unless self.class.part_type?(p).eql?('text/html')
        d = Hpricot(p.body)
        title = d.at('title').inner_html
        doc = d if title =~ /You have new Picture Mail!/
      end
      return if doc.nil? #it was a dud

      # break it down
      sprint_phone_number(doc)
      sprint_process_text(doc)
      sprint_process_media(doc)

    end

    private

    ##
    # Digs out where Sprint hides the phone number

    def sprint_phone_number(doc)
      c = doc.search("/html/head/comment//").last
      t = c.content.gsub(/\s+/m," ").strip
      #@number returned in parent's get_number
      @number = / name=&quot;MDN&quot;&gt;(\d+)&lt;/.match(t)[1]
    end

    ##
    # pulls out the user text form the MMS and adds the text
    # to media hash

    def sprint_process_text(doc)
      # there is at least one <pre> with MMS text if text has been included by
      # the user.  (note) we'll have to verify that if they attach multiple texts 
      # to the MMS then Sprint stacks it up in multiple <pre>'s.  The only <pre> 
      # tag in the document is for text from the user.
      doc.search("/html/body//pre").each do |pre|
        type = 'text/plain'
        text = pre.inner_html.strip
        next if text.size == 0
        type, text = transform_text(type, text)
        type, file = sprint_write_file(type, text.strip)
        add_file(type, file) unless type.nil? || file.nil?
      end
    end

    ##
    # Fetch all the media that is referred to in the doc

    def sprint_process_media(doc)
      srcs = Array.new
      # collect all the images in the document, even though
      # they are <img> tag some might actually refer to video.
      # To know the link refers to vide one must look at the 
      # content type on the http GET response.
      imgs = doc.search("/html/body//img")
      imgs.each do |i|
        src = i.attributes['src']
        # we don't want to double fetch content and we only
        # want to fetch media from the content server, you get
        # a clue about that as there is a RECIPIENT in the URI path
        # of real content
        next unless /mmps\/RECIPIENT\//.match(src)
        next if srcs.detect{|s| s.eql?(src)}
        srcs << src
      end

      #we've got the payload now, go fetch them
      cnt = 0
      srcs.each do |src|
        begin
          url = URI.parse(src)
          #res = Net::HTTP.get_response(url)
          #lets be vanilla stealth
          agent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2; SV1; .NET CLR 1.1.4322)"
          res = Net::HTTP.start(url.host, url.port) do |http|
            req = Net::HTTP::Get.new(url.request_uri, {'User-Agent' => agent})
            http.request(req)
          end
        rescue
          @logger.error("#{self.class} processing error, #{$!}") unless @logger.nil?
          next
        end

        # setup the file path and file
        base = /\/RECIPIENT\/([^\/]+)\//.match(src)[1]
        type = res.content_type
        file_name = "#{base}-#{cnt}.#{self.class.default_ext(type)}"
        file = File.join(msg_tmp_dir(),File.basename(file_name))

        # write it and add it to the media hash
        type, file = sprint_write_file(type, res.body, file)
        add_file(type, file) unless type.nil? || file.nil?
        cnt = cnt + 1
      end

    end

    ##
    # Creates a temporary file based on the type

    def sprint_temp_file(type)
      file_name = "#{Time.now.to_f}.#{self.class.default_ext(type)}"
      File.join(msg_tmp_dir(),File.basename(file_name))
    end

    ##
    # Writes the content to a file and returns the type, file as a tuple.
    def sprint_write_file(type, content, file = nil)
      file = sprint_temp_file(type) if file.nil?
      @logger.info("#{self.class} writing file #{file}") unless @logger.nil?
      File.open(file,'w'){ |f|
        f.write(content)
      }
      return type, file
    end

  end
end
