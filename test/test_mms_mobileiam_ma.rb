require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMmsMobileiamMa < Test::Unit::TestCase
  include MMS2R::TestHelper
  
  def test_image_and_number
    mail = TMail::Mail.parse(load_mail('maroctelecom-france-mms-01.mail').join)
    mms = MMS2R::Media.new(mail)
    
    assert_equal "98765432101", mms.number

    assert_equal 1, mms.media.size

    assert_equal 1, mms.media['image/gif'].size
    assert_match(/jalwapam\.gif$/, mms.media['image/gif'].first)
    assert_equal 1855, File.size(mms.media['image/gif'].first)

    mms.purge
  end
end
