module MMS2R

  ##
  # Cingular Me version of MMS2R::Media
  #
  # The characteristics of Cingular Me is that its the
  # MMS version of a SMS, essentially just a non-multipart
  # (plain) email.
  # 
  # The default Subject from the carrier these messages
  # is just an empty string
  #
  # There is often a text footer in these messages:
  #
  # --
  # ===============================================
  # Brought to you by, Cingular Wireless Messaging
  # http://www.CingularMe.COM/
  #

  class MMS2R::CingularMeMedia < MMS2R::Media
  end
end
