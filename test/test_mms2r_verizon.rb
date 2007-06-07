$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class TestMms2rVerizon < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
    @ad = "This message was sent using PIX-FLIX Messaging service from Verizon Wireless!\nTo learn how you can snap pictures with your wireless phone visit\nwww.verizonwireless.com/getitnow/getpix."
    @greet = "This message was sent using PIX-FLIX Messaging service from Verizon Wireless!"
  end

  def teardown; end

  def test_simple_video
    mail = TMail::Mail.parse(load_mail('verizon-video-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['video/3gpp2'][0]
    assert_match(/012345_67890.3g2$/, mms.media['video/3gpp2'][0])

    assert_file_size mms.media['video/3gpp2'][0], 16553

    mms.purge
  end

  def test_simple_image
    mail = TMail::Mail.parse(load_mail('verizon-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal MMS2R::VerizonMedia, mms.class, "expected a #{MMS2R::VerizonMedia} and received a #{mms.class}"

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/IMAGE_00004.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_text
    mail = TMail::Mail.parse(load_mail('verizon-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::VerizonMedia, mms.class, "expected a #{MMS2R::VerizonMedia} and received a #{mms.class}"
    mms.process
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

  def test_image_with_body_text
    mail = TMail::Mail.parse(load_mail('verizon-image-02.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/04-09-07_1114.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337
    
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert !text.match(@ad), "found ad in text"
    assert !text.match(@greet), "found ad in text"
    assert_equal "? Weird", text
    
    mms.purge
  end

  
end
