2/23/2010
Version 2.4.1 of MMS2R is the last TMail based MMS2R.  TMail
http://tmail.rubyforge.org/ has been deemed to be a legacy gem and the most
RFC compliant Ruby gem for everything email related is now Mail
http://github.com/mikel/mail .  I may back-port configuration settings to the
old MMS2R code base which will live in the legacy_tmail_branch branch and
publish point releases for 2.4.X.  But I may not so don't count on it.  Version
3.0.0 of MMS2R will be the master branch going forward and will be dependent on
the Mail gem.
Thank you
Mike

7/24/2010
If you want to use Mail instead of TMail in an Rails 2.3 or lower ActionMailer
this is one way to do it:

http://gist.github.com/486883


class MailReceiver < ActionMailer::Base

  # patch ActionMailer::Base to put a ActionMailer::Base#raw_email 
  # accessor on the created instance
  class << self
    alias :old_receive :receive
    def receive(raw_email)
      send(:define_method, :raw_email) { raw_email }
      self.old_receive(raw_email)
    end
  end

  ##
  # Injest email/MMS here

  def receive(tmail)
    # completely ignore the tmail object rails passes in Rails 2.*

    mail = Mail.new(self.raw_email)
    mms = MMS2R::Media.new(mail, :logger => Rails.logger)

    # do something
  end
end
