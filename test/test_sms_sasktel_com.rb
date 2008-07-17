require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestSmsSasktelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_sms_sasktel_com
    # sms.sasktel.com service
    mail = TMail::Mail.parse(load_mail('sasktel-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "sms.sasktel.com", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/A1.8463391017738573.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    mms.purge
  end

end
