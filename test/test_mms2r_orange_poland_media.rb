$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2R::OrangePolandMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_empty_subject
    mail = TMail::Mail.parse(load_mail('orangepoland-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::OrangePolandMedia, mms.class, "expected a #{MMS2R::OrangePolandMedia} and received a #{mms.class}"
    mms.process
    assert_nil mms.subject
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_match(/pozdro600/, text)
    mms.purge
  end
  
  def test_non_empty_subject
    mail = TMail::Mail.parse(load_mail('orangepoland-text-02.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::OrangePolandMedia, mms.class, "expected a #{MMS2R::OrangePolandMedia} and received a #{mms.class}"
    mms.process
    assert mms.subject, "whazzup"
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_match(/pozdro600/, text)
    mms.purge
  end
end
