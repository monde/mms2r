require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsLuxgsmLu < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject
    mail = TMail::Mail.parse(load_mail('luxgsm-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "MMS2R - LUXGSM", mms.subject

    mms.purge
  end

  def test_number
    mail = TMail::Mail.parse(load_mail('luxgsm-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "+5551234", mms.number

    mms.purge
  end

  def test_image
    mail = TMail::Mail.parse(load_mail('luxgsm-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_equal 2, mms.media['image/gif'].size
  
    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = TMail::Mail.parse(load_mail('luxgsm-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    file = mms.default_media
    assert_equal 8897, file.size
    
    mms.purge
  end 

  def test_default_text_should_return_user_generated_content
    mail = TMail::Mail.parse(load_mail('luxgsm-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    file = mms.default_text
    assert_nil file

    # TODO need more fixtures to handle text tests
    
    mms.purge
  end 
  
end
