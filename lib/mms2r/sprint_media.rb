require 'net/http'
require 'rubygems'
require 'hpricot'
require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Sprint version of MMS2R::Media

  class MMS2R::SprintMedia < MMS2R::Media

    ##
    # MMS2R::SprintMedia has to override process_media because Sprint
    # doesn't attach media (images, video, etc.) to it MMS.  Media such
    # as images and videos are hosted on a Sprint content server. 
    # MMS2R::SprintMedia has to pick apart an HTML attachment to find
    # the URL to the media on Sprint's content server.

    def process_media(part)
      part.base64_decode
      if self.class.part_type?(part).eql?('text/plain')
        file_name = filename?(part)
        type, content = transform_text(part)
      elsif self.class.part_type?(part).eql?('text/html')
        doc = Hpricot(part.body)
        trs = doc.search("/html/body//tr")
        imgs = doc.search("/html/body//img")
        img = imgs[2].attributes['src']
        #here's where the content is, now download it
        url = URI.parse(img)
        req = Net::HTTP::Get.new(url.path)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        file_name ="#{img.match(/\/RECIPIENT\/([^\/]+)\//)[1]}.#{self.class.default_ext(res.content_type)}"
        type = res.content_type
        content = res.body
      end
      file = File.join(msg_tmp_dir(),file_name)
      @logger.info("#{self.class} writing file #{file}") unless @logger.nil?
      File.open(file,'w'){ |f|
        f.write(content)
      }
      return type, file
    end
  end
end
