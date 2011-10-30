require "test_helper"

class TestMsgTelusCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject_number_image
    mail = mail('telus-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
    assert_equal "2068675309", mms.number
    assert_equal "mms.telusmobility.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /Lil bud 2.jpg/ =~ f}
    assert_equal 337, File.size(image)

    mms.purge
  end

end
