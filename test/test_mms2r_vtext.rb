$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class TestMms2rVtext < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_simple_text_vtext

    mail = TMail::Mail.parse(load_mail('vtext-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::VtextMedia, mms.class, "expected a #{MMS2R::VtextMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

end
