module MMS2R

  ##
  # Verizon version of MMS2R::Media
  #
  # Typically there are two parts to a Verizon MMS
  # if its just for a image for example.  The first part
  # is text with a message that says the MMS is being
  # sent from a Verizon subscriber.  If the MMS also
  # contains a user generated message then that will be
  # at the top of the text greeting from Verizon.  The 
  # part of the MMS is the media itself.
  #
  # The default subject on these MMS is the empty
  # string if the user has not already specified one.

  class MMS2R::VerizonMedia < MMS2R::Media
  end
end
