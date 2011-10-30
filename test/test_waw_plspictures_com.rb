require "test_helper"

class TestWawPlspicturesCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_www_plspictures_com
    mail = mail('waw.plspictures.com-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "waw.plspictures.com", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/A0.7585991693329067.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    mms.purge
  end

end
