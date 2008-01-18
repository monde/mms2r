require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestPxtVodafoneNetNz < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    mail = TMail::Mail.parse(load_mail('pxt-image-01.mail').join)
    @mms = MMS2R::Media.new(mail)
  end
  
  def teardown
    @mms.purge
  end

  def test_pxt_text_returns_text_plain
    assert_not_nil(@mms.media['text/plain'])
    
    file = @mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/Kia ora ano Luke/, text)
    
    assert_match(/Kia ora ano Luke/, @mms.body)
  end
  
  def test_subject_should_clear_default_pxt_message
    assert_equal "", @mms.subject
  end

end
