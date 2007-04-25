require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Dobson/Cellular One version version of MMS2R::Media
  # So far, Dobson MMS messages do not contain advertising
  # They do, however, have a weird SMIL file attachment. It
  # can be safely ignored.
  
  class MMS2R::DobsonMedia < MMS2R::Media
  end
end
