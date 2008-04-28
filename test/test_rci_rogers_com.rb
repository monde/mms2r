require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestRciRogersCom < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_and_text_and_number
    mail = TMail::Mail.parse(load_mail('rogers-canada-mms-01.mail').join)
    mms = MMS2R::Media.new(mail)

    assert_equal "1234567890", mms.number
    assert_equal "", mms.subject

    assert_equal 1, mms.media.size
    assert_equal 2, mms.media['image/jpeg'].size

    #janky test because there is a verisign logo in the file
    assert_not_nil mms.media['image/jpeg'].first
    assert mms.media['image/jpeg'].detect{|f| /A2.2658324049556002.jpg$/ =~ f}
    mms.purge
  end

end
