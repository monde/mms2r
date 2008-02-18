require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestBellsouthNet < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_from_blackberry
    mail = TMail::Mail.parse(load_mail('suncom-blackberry.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_nil mms.media['text/plain']
    
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Windows-1252\?B\?SU1HMDAwNjUuanBn/, mms.media['image/jpeg'].first)
    mms.purge
  end
end
