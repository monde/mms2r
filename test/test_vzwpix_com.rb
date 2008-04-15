require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestVzwpixCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @ad = "This message was sent using PIX-FLIX Messaging service from Verizon Wireless!\nTo learn how you can snap pictures with your wireless phone visit\nwww.verizonwireless.com/getitnow/getpix."
    @greet = "This message was sent using PIX-FLIX Messaging service from Verizon Wireless!"
  end

  def test_simple_video
    # vzwpix.com service
    mail = TMail::Mail.parse(load_mail('verizon-video-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['video/3gpp2'][0]
    assert_match(/012345_67890.3g2$/, mms.media['video/3gpp2'][0])

    assert_file_size mms.media['video/3gpp2'][0], 16553

    mms.purge
  end

  def test_simple_image
    # vzwpix.com service
    mail = TMail::Mail.parse(load_mail('verizon-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/IMAGE_00004.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image_new_message_april_2008
    # vzwpix.com service
    mail = TMail::Mail.parse(load_mail('verizon-image-03.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/0414082054.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_text
    # vzwpix.com service
    mail = TMail::Mail.parse(load_mail('verizon-text-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)

    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

  def test_image_with_body_text
    # vzwpix.com service
    mail = TMail::Mail.parse(load_mail('verizon-image-02.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/04-09-07_1114.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337
    
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)
    text = IO.readlines("#{file}").join
    assert_no_match(/Regexp.escape(@ad)/, text)
    assert_no_match(/Regexp.escape@greet/, text)
    assert_equal "? Weird", text
    
    mms.purge
  end

  def test_simple_text_vtext
    # vtext.com service
    mail = TMail::Mail.parse(load_mail('vtext-text-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end
  
  def test_image_from_blackberry
    mail = TMail::Mail.parse(load_mail('verizon-blackberry.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_not_nil mms.media['text/plain']
    assert_equal "Wonderful picture!", IO.readlines(mms.media['text/plain'].first).join.strip
    
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Windows-1252\?B\?SU1HMDAwMTYuanBn/, mms.media['image/jpeg'].first)
    mms.purge
  end

end
