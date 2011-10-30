require "test_helper"

class TestVmpixCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_only_valid_content_should_be_retained_for_mms_with_image_and_text
    mail = mail('virgin-mobile-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "vmpix.com", mms.carrier
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_file_size(mms.media['image/jpeg'].first, 337)
    assert_match(/pic100508_3.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_number_should_return_correct_number
    mail = mail('virgin-mobile-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "vmpix.com", mms.carrier
    mms.purge
  end

  def test_subject_should_return_correct_subject
    mail = mail('virgin-mobile-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "vmpix.com", mms.carrier
    assert_equal "Jani sleepy", mms.subject
    mms.purge
  end

  def test_attachment_should_return_jpeg
    mail = mail('virgin-mobile-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "vmpix.com", mms.carrier
    image = mms.default_media
    assert_equal 337, image.size
    assert_equal "pic100508_3.jpg", image.original_filename
    mms.purge
  end

  def test_only_valid_content_should_be_retained_for_virgin_canada_text
    mail = mail('virgin.ca-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal 'vmobile.ca', mms.carrier
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Hello World", IO.read(mms.media['text/plain'][0]).strip
    mms.purge
  end

end
