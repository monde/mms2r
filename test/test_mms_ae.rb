require "test_helper"

class TestMmsAe < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_only_valid_content_should_be_retained_for_mms_with_image_and_text
    mail = mail('mms.ae-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.ae", mms.carrier
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_file_size(mms.media['image/jpeg'].first, 337)
    assert_match(/19102008.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_number_should_return_correct_number
    mail = mail('mms.ae-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.ae", mms.carrier
    mms.purge
  end

  def test_subject_should_return_correct_subject
    mail = mail('mms.ae-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.ae", mms.carrier
    assert_equal "", mms.subject
    mms.purge
  end

  def test_attachment_should_return_jpeg
    mail = mail('mms.ae-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.ae", mms.carrier
    image = mms.default_media
    assert_equal 337, image.size
    assert_equal "19102008.jpg", image.original_filename
    mms.purge
  end

end
