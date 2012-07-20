require "test_helper"

class TestMmsCincinnatiBell < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_mms_image_cincinnati_bell
    # sms.sasktel.com service
    mail = mail('cincinnati-bell-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "12223334444", mms.number
    assert_equal "mms.gocbw.com", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']
    # we have media and text, to 2 media items
    assert_equal 2, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/test-file.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 106024)
    mms.purge
  end

end
