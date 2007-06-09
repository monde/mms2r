module MMS2R

  ##
  # T-Mobile version of MMS2R::Media
  #
  # T-Mobile MMS have the user's content in them as
  # a multipart but they also frame that content in
  # a HTML document.  They also attach a number of small
  # images with the MMS that are used in the HTML so that
  # if an email reader is used to view the message then
  # the message is framed nicely by pretty T-Mobile
  # logos.  MMS2R throws out all that junk and leaves the
  # the user generated content.
  #
  # The default subject of the MMS from the carrier
  # is the empty string if the user did not set
  # the subject explicitly.

  class MMS2R::TMobileMedia < MMS2R::Media
  end
end
