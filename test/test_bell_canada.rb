require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestBellCanada < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_and_text_and_number
    mail = TMail::Mail.parse(load_mail('bell-canada-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal "2068675309", mms.number
    assert_equal "A Picture/Video Message!", mms.subject

    assert_equal 4, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_equal 6, mms.media['image/gif'].size
    assert_equal 1, mms.media['text/html'].size
    assert_equal 1, mms.media['text/plain'].size

    # make sure transform strips out massive dtd at start of doc
    assert_equal 3331, File.size(mms.media['text/html'].first)
    
    mms.purge
  end


  def test_default_media_should_return_user_generated_content
    mail = TMail::Mail.parse(load_mail('bell-canada-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    file = mms.default_media
    
    # make sure the users jpg is the one that we default to
    assert_equal 31962, file.size
    assert_equal '.jpg', File.extname(file.path)
    
    mms.purge
  end 

end
