$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2R::AlltelMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_alltel_image
    mail = TMail::Mail.parse(load_mail('alltel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal mms.class, MMS2R::AlltelMedia

    mms.process
  
    assert_equal 1, mms.media.size, "Size is #{mms.media.size}"
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/eastern sky.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337
  
    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = TMail::Mail.parse(load_mail('alltel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    file = mms.default_media
    assert_equal 'eastern sky.jpg', file.original_filename
    mms.purge
  end 
  
end
