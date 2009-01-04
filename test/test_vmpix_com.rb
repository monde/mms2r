require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestVmpixCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_only_valid_content_should_be_retained_for_mms_with_image_and_text
    mail = TMail::Mail.parse(load_mail('virgin-mobile-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_file_size(mms.media['image/jpeg'].first, 337)
    assert_match(/pic100508_3.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_number_should_return_correct_number
    mail = TMail::Mail.parse(load_mail('virgin-mobile-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    number = mms.number()
    assert_equal number, 2068675309.to_s
    mms.purge
  end

  def test_subject_should_return_correct_subject
    mail = TMail::Mail.parse(load_mail('virgin-mobile-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "Jani sleepy", mms.subject
    mms.purge
  end

  def test_attachment_should_return_jpeg
    mail = TMail::Mail.parse(load_mail('virgin-mobile-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    image = mms.default_media
    assert_equal 337, image.size
    assert_equal "pic100508_3.jpg", image.original_filename
    mms.purge
  end

  def test_only_valid_content_should_be_retained_for_virgin_canada_text
    mail = TMail::Mail.parse(load_mail('virgin.ca-text-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal 'vmobile.ca', mms.carrier
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Hello World", IO.read(mms.media['text/plain'][0]).strip
    mms.purge
  end

end
