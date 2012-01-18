require "test_helper"

class TestInvalidByteSeqOutlook < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_bad_outlook
    mail = mail('invalid-byte-seq-outlook.mail')
    mms = MMS2R::Media.new(mail)
    body = mms.body
=begin

    assert_equal "+919812345678", mms.number
    assert_equal "1nbox.net", mms.carrier
    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "testing123456789012", open(mms.media['text/plain'].first).read

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['text/plain'].size
    assert_match(/@003\.jpg$/, mms.media['image/jpeg'].first)
=end

    mms.purge
  end
end
