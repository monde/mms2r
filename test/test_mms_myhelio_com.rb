require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsMyhelioCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_only_valid_content_should_be_retained_for_mms_with_image_and_text
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_equal 1, mms.media['text/plain'].size
    mms.purge
  end

  def test_only_valid_content_should_be_retained_for_mms_with_text
    mail = TMail::Mail.parse(load_mail('helio-message-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    mms.purge
  end

  def test_number_should_return_correct_number
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    number = mms.number()
    assert_equal number, 5551234.to_s
    mms.purge
  end

  def test_subject_should_return_correct_subject
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    title = mms.subject()
    assert_equal title, "Test image"
    mms.purge
  end

  def test_body_should_return_correct_body
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    body = mms.body()
    assert_equal body, "Test image"
    mms.purge
  end

  def test_attachment_should_return_jpeg
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    image = mms.default_media()
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/0628070005.jpg$/, mms.media['image/jpeg'][0])
    mms.purge
  end

end
