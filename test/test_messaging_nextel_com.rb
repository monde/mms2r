require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMessagingNextelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_simple_text_is_nil
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_nil mms.default_text

    mms.purge
  end

  def test_simple_default_media
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    file = mms.default_media
    assert_file_size file, 337
    assert_equal 'Jan15_0001.jpg', file.original_filename
    assert_equal 337, file.size
    assert_match(/Jan15_0001.jpg$/, file.local_path)

    mms.purge
  end

  def test_simple_image1
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Jan15_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image2
    mail = TMail::Mail.parse(load_mail('nextel-image-02.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Mar12_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image3
    mail = TMail::Mail.parse(load_mail('nextel-image-03.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Apr01_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image4
    mail = TMail::Mail.parse(load_mail('nextel-image-04.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Mar20_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end
end
