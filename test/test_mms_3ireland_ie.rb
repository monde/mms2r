require "test_helper"

class TestMms3irelandIe < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image_and_text_and_number
    mail = mail('3ireland-mms-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "351234567890", mms.number
    assert_equal "mms.3ireland.ie", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    assert_match(/Image013\.jpg$/, mms.media['image/jpeg'].first)
    assert_equal 337, File.size(mms.media['image/jpeg'].first)

    mms.purge
  end
end
