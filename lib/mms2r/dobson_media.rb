require 'mms2r'

require 'mms2r/media'

module MMS2R

  ##
  # Dobson/Cellular One version version of MMS2R::Media
  #
  # So far, Dobson MMS messages do not contain advertising
  # They do, however, have a SMIL part that gives markup
  # structure to any user generated content the MMS may
  # contain and can be safely ignored.
  
  class MMS2R::DobsonMedia < MMS2R::Media
  end
end
