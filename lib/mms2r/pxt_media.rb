module MMS2R

  ##
  # PXT version of MMS2R::Media
  #
  # PXT is a mobile carrier from New Zealand.
  # Any text message is stored in a text/plain part 
  # (all HTML can be ignored).

  class MMS2R::PxtMedia < MMS2R::Media
    def default_text
      return @default_text ||= attachement(['text/plain'])
    end
  end
end
