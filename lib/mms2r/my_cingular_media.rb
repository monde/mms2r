require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # My Cingular version of MMS2R::Media
  #
  # The Cingular MMS messages are well formed multipart
  # mails and do not contain any extra advertising or
  # mark up for structure.
  #
  # The default subject from the carrier if the user does
  # not provide one is "Multimedia message"

  class MMS2R::MyCingularMedia < MMS2R::Media
  end
end
