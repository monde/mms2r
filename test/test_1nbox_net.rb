require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class Test1nboxNet < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_and_text_and_number
    mail = TMail::Mail.parse(load_mail('1nbox-2images-01.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_equal "+919812345678", mms.number
    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "testing123456789012", open(mms.media['text/plain'].first).read

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['text/plain'].size
    assert_match(/@003\.jpg$/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_no_plain_text
    mail = TMail::Mail.parse(load_mail('1nbox-2images-02.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_nil mms.media['text/plain']

    assert_equal "+919898765432", mms.number
    assert_equal 1, mms.media.size
    
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/showpicture\.jpeg$/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_extra_chars
    mail = TMail::Mail.parse(load_mail('1nbox-2images-03.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/=\?UTF-8\?Q\?Copy_of_test1\.jpg\?=/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_plain_email
    mail = TMail::Mail.parse(load_mail('1nbox-2images-04.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Hi,I'M TESTERS/MALE/23/IND/GOV.SRVC.01234567890.", open(mms.media['text/plain'].first).read

    assert_equal "1234567890", mms.number
    
    assert_not_nil mms.media['image/gif']
    assert_equal 1, mms.media['image/gif'].size
    assert_match(/@003\.gif$/, mms.media['image/gif'].first)

    mms.purge
  end
end
