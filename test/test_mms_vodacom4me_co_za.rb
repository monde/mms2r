require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsVodacom4meCoZa < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_only
    mail = TMail::Mail.parse(load_mail('vodacom4me-co-za-01.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Ugly\.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

=begin
TODO is the phone number always in the from or sender?
From: "+2068675309" <ASZFZH@mms.vodacom4me.co.za>
Sender: "+2068675309" <ASZFZH@mms.vodacom4me.co.za>

  def test_should_have_phone_number
    mail = TMail::Mail.parse(load_mail('vodacom4me-co-za-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal '+2068675309', mms.number
    
    mms.purge
  end
=end
  
  def test_image_and_text
    mail = TMail::Mail.parse(load_mail('vodacom4me-co-za-02.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_not_nil mms.media['text/plain']
    assert_equal "Hello World", open(mms.media['text/plain'].first).read
    
    assert_nil mms.media['text/html']
    
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/DSC00184\.JPG$/, mms.media['image/jpeg'].first)
    mms.purge
  end
end
