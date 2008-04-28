require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsMycricketCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject
    # mms.mycricket.com service
    mail = TMail::Mail.parse(load_mail('mms.mycricket.com-pic.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "", mms.subject
    mms.purge
  end

  def test_image
    # mms.mycricket.com service
    mail = TMail::Mail.parse(load_mail('mms.mycricket.com-pic.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/10-26-07_1739.jpg$/, mms.media['image/jpeg'].first)

    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end

  def test_image_and_text
    # mms.mycricket.com service
    mail = TMail::Mail.parse(load_mail('mms.mycricket.com-pic-and-text.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size
    assert_nil mms.media['text/html']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['text/plain'].first
    assert_not_nil mms.media['image/jpeg'].first

    file = mms.media['text/plain'].first
    assert_equal true, File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_match(/Hello World/, text)

    assert_match(/02-14-08_2114.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end

end
