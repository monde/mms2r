require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Sprint PCS version of MMS2R::Media
  #
  # This is a SMS message from a Sprint subscriber
  # that is transformed into an MMS so it can leave the
  # Sprint network.  Its not a multipart email, its
  # body is the message.
  #
  # The subject of these MMS are always the
  # empty string.

  class MMS2R::SprintPcsMedia < MMS2R::Media
  end
end
