#--
# Copyright (c) 2007-2012 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information.
#++

require 'net/http'
require 'nokogiri'
require 'cgi'
require 'json'

module MMS2R

  class Media
    ##
    # Sprint version of MMS2R::Media
    #
    # Sprint is an annoying carrier because they don't actually transmit user
    # generated content (like images or videos) directly in the MMS message.
    # Instead, they hijack the media that is sent from the cellular subscriber
    # and place that content on a content server.  In place of the media
    # the recipient receives a HTML message with unsolicited Sprint
    # advertising and links back to their content server.  The recipient has
    # to click through Sprint more pages to view the content.
    #
    # The default subject on these messages from the
    # carrier is "You have new Picture Mail!"

    module Sprint

      protected

      ##
      # Helper to process old style media on the Sprint CDN which didn't attach
      # media (images, video, etc.) to its MMS.  Media such as images and
      # videos are hosted on a Sprint content server.  MMS2R::Media::Sprint has
      # to pick apart an HTML attachment to find the URL to the media on
      # Sprint's content server and download each piece of content.  Any text
      # message part of the MMS if it exists is embedded in the html.

      def process_html_part(part)
        doc = Nokogiri(part.body.decoded)

        is_video = (part.body.decoded =~ /type=&quot;VIDEO&quot;&gt;/m ? true : false)
        sprint_process_media(doc, is_video)
        sprint_process_text(doc)
        sprint_phone_number(doc)
      end

      ##
      # Digs out where Sprint hides the phone number

      def sprint_phone_number(doc)
        c = doc.search("/html/head/comment()").last
        t = c.content.gsub(/\s+/m," ").strip
        #@number returned in parent's #number
        matched = / name=&quot;MDN&quot;&gt;(\d+)&lt;/.match(t)
        @number = matched[1] if matched
      end

      ##
      # Pulls out the user text form the MMS and adds the text to media hash

      def sprint_process_text(doc)
        # there is at least one <pre> with MMS text if text has been included by
        # the user.  (note) we'll have to verify that if they attach multiple texts
        # to the MMS then Sprint stacks it up in multiple <pre>'s.  The only <pre>
        # tag in the document is for text from the user.
        # if there is no text media found in the mail body - then we go to more
        # extreme measures.
        text_found = false

        doc.search("/html/body//pre").each do |pre|
          type = 'text/plain'
          text = pre.inner_html.strip
          next if text.empty?

          text_found = true
          type, text = transform_text(type, text)
          type, file = sprint_write_file(type, text.strip)
          add_file(type, file) unless type.nil? || file.nil?
        end
        # if no text was found, there still might be a message with images
        # that can be seen at the end of the "View Entire Message" link
        if !text_found
          view_entire_message_link = doc.search("a").find { |link| link.inner_html == "View Entire Message"}
          # if we can't find the view entire message link, give up
          if view_entire_message_link
            # Sprint uses AJAX/json to serve up the content at the end of the link so this is conveluted
            url = view_entire_message_link.attr("href")
            # extract the "invite" param out of the url - this will be the id we pass to the ajax path below
            inviteMessageId = CGI::parse(URI::parse(url).query)["invite"].first

            if inviteMessageId
              json_url = "http://pictures.sprintpcs.com/ui-refresh/guest/getMessageContainerJSON.do%3FcomponentType%3DmediaDetail&invite=#{inviteMessageId}&externalMessageId=#{inviteMessageId}"
              # pull down the json from the url and parse it
              uri = URI.parse(json_url)
              connection = Net::HTTP.new(uri.host, uri.port)
              response = connection.get2(
                uri.request_uri,
                { "User-Agent" => MMS2R::Media::USER_AGENT }
              )
              content = response.body

              # if the content has expired, sprint sends back html "content expired page
              # json will fail to parse
              begin
                json = JSON.parse(content)

                # there may be multiple "results" in the json - due to multiple images
                # cycle through them and extract the "description" which is the text
                # message the sender sent with the images
                json["Results"].each do |result|
                  type = 'text/plain'
                  # remove any &nbsp; chars from the resulting text
                  text = result["description"] ? result["description"].gsub(/[[:space:]]/, " ").strip : nil
                  next if text.empty?
                  type, text = transform_text(type, text)
                  type, file = sprint_write_file(type, text.strip)
                  add_file(type, file) unless type.nil? || file.nil?
                end
              rescue JSON::ParserError => e
                log("#{self.class} processing error, #{$!}", :error)
              end
            end
          end
        end
      end

      ##
      # Fetch all the media that is referred to in the doc

      def sprint_process_media(doc, is_video=false)
        srcs = Array.new
        # collect all the images in the document, even though
        # they are <img> tag some might actually refer to video.
        # To know the link refers to vide one must look at the
        # content type on the http GET response.
        imgs = doc.search("/html/body//img")
        imgs.each do |i|
          src = i.attributes['src']
          next unless src
          src = src.text
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

            uri = URI.parse(CGI.unescapeHTML(src))
            unless is_video
              query={}
              uri.query.split('&').each{|a| p=a.split('='); query[p[0]] = p[1]}
              query.delete_if{|k, v| k == 'limitsize' || k == 'squareoutput' }
              uri.query = query.map{|k,v| "#{k}=#{v}"}.join("&")
            end
            # sprint is a ghetto, they expect to see &amp; for video request
            uri.query = uri.query.gsub(/&/, "&amp;") if is_video

            connection = Net::HTTP.new(uri.host, uri.port)
            #connection.set_debug_output $stdout
            response = connection.get2(
              uri.request_uri,
              { "User-Agent" => MMS2R::Media::USER_AGENT }
            )
            content = response.body
          rescue StandardError => err
            log("#{self.class} processing error, #{$!}", :error)
            next
          end
          # if the Sprint content server uses response code 500 when the content is purged
          # the content type will text/html and the body will be the message
          if response.content_type == 'text/html' && response.code == "500"
            log("Sprint content server returned response code 500", :error)
            next
          end

          # setup the file path and file
          base = /\/RECIPIENT\/([^\/]+)\//.match(src)[1]
          type = response.content_type
          file_name = "#{base}-#{cnt}.#{self.class.default_ext(type)}"
          file = File.join(msg_tmp_dir(),File.basename(file_name))

          # write it and add it to the media hash
          type, file = sprint_write_file(type, content, file)
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
        log("#{self.class} writing file #{file}", :info)
        # force the encoding to be utf-8
        content = content.force_encoding("UTF-8") if content.respond_to?(:force_encoding)
        File.open(file,'w'){ |f| f.write(content) }
        return type, file
      end

    end
  end
end
