require "test_helper"

class TestMmsThreeCoUk < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject
    mail = mail('three-uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.three.co.uk", mms.carrier
    assert_equal "", mms.subject

    mms.purge
  end

  def test_image
    mail = mail('three-uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.three.co.uk", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/17102007.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = mail('three-uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.three.co.uk", mms.carrier
    file = mms.default_media
    assert_equal '17102007.jpg', file.original_filename

    mms.purge
  end

end
