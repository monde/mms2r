require "test_helper"

class Testprint < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_sprint_blackberry_01
    # Rim Exif Version1.00a
    mail = mail('sprint-blackberry-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal true, mms.is_mobile?
    assert_equal :blackberry, mms.device_type?
    assert_equal "", mms.body
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    mms.purge
  end
end
