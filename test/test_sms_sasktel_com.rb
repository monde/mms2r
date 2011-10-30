require "test_helper"

class TestSmsSasktelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_sms_sasktel_com
    # sms.sasktel.com service
    mail = mail('sasktel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "3068675309", mms.number
    assert_equal "sms.sasktel.com", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/A1.8463391017738573.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    mms.purge
  end

end
