require 'mms2r'
require 'mms2r/media'

module MMS2R

  ##
  # MMode version of MMS2R::Media
  #
  # The only examples of MMode seen so far do not
  # contain advertising and the subject of the
  # message is the file name of the media attached
  # to the MMS.

  class MMS2R::MModeMedia < MMS2R::Media
  end
end
