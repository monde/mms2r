require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsMtnCoZa < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_and_text_and_number
    mail = TMail::Mail.parse(load_mail('mtn-southafrica-mms.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_equal "22222222222", mms.number

    assert_equal 1, mms.media.size
    assert_nil mms.media['image/bmp']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Obsession Obsession", open(mms.media['text/plain'].first).read

    mms.purge
  end
end
