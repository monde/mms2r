$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2R::CingularMeMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @ad = "\n--\n===============================================\nBrought to you by, Cingular Wireless Messaging\nhttp://www.CingularMe.COM/"
    @greet = "Brought to you by, Cingular Wireless Messaging"
  end

  def test_clean_text_ad1
    mail = TMail::Mail.parse(load_mail('cingularme-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::CingularMeMedia, mms.class, "expected a #{MMS2R::CingularMeMedia} and received a #{mms.class}"
    mms.process
    assert_not_nil mms.media['text/plain'] 
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert !text.match(@ad), "found ad in text"
    assert !text.match(@greet), "found ad in text"
    assert_equal "hello world", text
    mms.purge
  end

  def test_clean_text_ad2
    mail = TMail::Mail.parse(load_mail('cingularme-text-02.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::CingularMeMedia, mms.class, "expected a #{MMS2R::CingularMeMedia} and received a #{mms.class}"
    mms.process
    assert_not_nil mms.media['text/plain'] 
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert !text.match(@ad), "found ad in text"
    assert !text.match(@greet), "found ad in text"
    assert_equal "hello world\nfoo bar", text
    mms.purge
  end
  
end
