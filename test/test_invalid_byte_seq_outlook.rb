require "test_helper"

class TestInvalidByteSeqOutlook < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_bad_outlook
    mail = mail('invalid-byte-seq-outlook.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "RE: Issue 14794:Don M. says.. Aaron - I completed RNS Test Question 3, which was done as a 'Cargo Control Number' query. H", mms.subject
    assert_match /Don Doe said less than a minute ago/im, mms.body

    mms.purge
  end
end
