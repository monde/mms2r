require "test_helper"

class TestMmsMyhelioCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_only_valid_content_should_be_retained_for_mms_with_image_and_text
    mail = mail('helio-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_equal 1, mms.media['text/plain'].size
    mms.purge
  end

  def test_only_valid_content_should_be_retained_for_mms_with_text
    mail = mail('helio-message-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Test message", open(mms.media['text/plain'].first).read
    mms.purge
  end

  def test_number_should_return_correct_number
    mail = mail('helio-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    mms.purge
  end

  def test_subject_should_return_correct_subject
    mail = mail('helio-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    title = mms.subject()
    assert_equal title, "Test image"
    mms.purge
  end

  def test_body_should_return_correct_body
    mail = mail('helio-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    body = mms.body()
    assert_equal body, "Test image"
    mms.purge
  end

  def test_attachment_should_return_jpeg
    mail = mail('helio-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "mms.myhelio.com", mms.carrier
    image = mms.default_media()
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/0628070005.jpg$/, mms.media['image/jpeg'][0])
    mms.purge
  end

end
