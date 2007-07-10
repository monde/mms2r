require 'rubygems'
require 'hpricot'
module MMS2R

  ##
  # Helio version version of MMS2R::Media
  #
  # Helio has a clean multipart/mixed message format.  It
  # includes markup that holds some branding around the media
  # artifact.  If text is included with the message it is located
  # in the markup.
  
  class MMS2R::HelioMedia < MMS2R::Media
    def get_body
      text = get_text()
      d = Hpricot(text)
      body = d.search("//table/tr[2]/td/table/tr/td/table/tr[6]/td").inner_html
      body 
    end
  end
end
