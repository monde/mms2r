require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestWawPlspicturesCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_www_plspictures_com
    mail = TMail::Mail.parse(load_mail('waw.plspictures.com-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "waw.plspictures.com", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/A0.7585991693329067.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    mms.purge
  end

end
