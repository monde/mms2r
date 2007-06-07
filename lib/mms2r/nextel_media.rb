require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # Nextel version of MMS2R::Media
  #
  # Typically these messages have two multiparts, one is the
  # image attached to the MMS and the other is a multipart
  # alternative.  The alternative has text and html alternative 
  # parts announcing the fact that its a MMS message from 
  # Sprint Nextel and these parts can be ignored.
  #
  # The default subject on these messages from the carrier
  # is the name of the image or video attached to the message.

  class MMS2R::NextelMedia < MMS2R::Media
  end
end
