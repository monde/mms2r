require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Verizon/Vtext version of MMS2R::Media
  #
  # Vtext is a SMS message from a Verizon subscriber
  # that is transformed into an MMS so it can leave the
  # Verizon network.  Its not a multipart email, its
  # body is the message.
  #
  # The subject of the message is the same as the body 
  # of the message.

  class MMS2R::VtextMedia < MMS2R::Media
  end
end
