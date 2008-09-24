require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMsgTelusCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject_number_image
    mail = TMail::Mail.parse(load_mail('telus-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
    assert_equal "2068675309", mms.number

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /Lil%20bud%202.jpg/ =~ f}
    assert_equal 337, File.size(image) 

    mms.purge
  end
  
end
