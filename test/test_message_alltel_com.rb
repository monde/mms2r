require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMessageAlltelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_alltel_image
    mail = TMail::Mail.parse(load_mail('alltel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
  
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 2, mms.media['image/jpeg'].size
    assert_match(/eastern sky.jpg$/, mms.media['image/jpeg'][0])
    assert_match(/eastern sky.jpg$/, mms.media['image/jpeg'][1])
    assert_file_size mms.media['image/jpeg'][0], 337
    assert_file_size mms.media['image/jpeg'][1], 337
  
    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = TMail::Mail.parse(load_mail('alltel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    file = mms.default_media
    assert_equal 'eastern sky.jpg', file.original_filename
    mms.purge
  end 
  
end
