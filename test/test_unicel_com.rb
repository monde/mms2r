require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestUnicelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject_number_image_unicel
    mail = TMail::Mail.parse(load_mail('unicel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
#    assert_equal "1234567890", mms.number

    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /moto_0002\.jpg/ =~ f}
    assert_equal 337, File.size(image) 

    file = mms.media['text/plain'][0]
    text = IO.readlines("#{file}").join
    assert_match(/2068675309/, text)

    mms.purge
  end

  def test_subject_number_image_info2go
    mail = TMail::Mail.parse(load_mail('info2go-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
    assert_equal "2068675309", mms.number

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /Image047\.jpeg/ =~ f}
    assert_equal 337, File.size(image) 

    mms.purge
  end
  
end
