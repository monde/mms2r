$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2R::DobsonMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_dobson_image
    mail = TMail::Mail.parse(load_mail('dobson-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal mms.class, MMS2R::DobsonMedia

    mms.process
  
    assert_equal 2, mms.media.size, "Size is #{mms.media.size}"
    assert_not_nil mms.media['text/plain']
    assert_equal nil, mms.media['application/smil'] # dobson phones have weird SMIL that can be ignored.
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/04-18-07_1723.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337
  
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "Body", text.strip
    mms.purge
  end
  
  def test_body_should_return_user_text
    mail = TMail::Mail.parse(load_mail('dobson-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    
    assert_equal 'Body', mms.body
    
    mms.purge
  end
end
