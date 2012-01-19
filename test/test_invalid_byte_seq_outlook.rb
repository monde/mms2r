require "test_helper"

class TestInvalidByteSeqOutlook < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_bad_outlook
    mail = mail('invalid-byte-seq-outlook.mail')
    mms = MMS2R::Media.new(mail)
    body = mms.body
    assert_match /Please have express change/,body
    mms.purge
  end
end
