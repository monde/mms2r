$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2R::PxtMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    mail = TMail::Mail.parse(load_mail('pxt-image-01.mail').join)
    @mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::PxtMedia, @mms.class, "expected a #{MMS2R::PxtMedia} and received a #{@mms.class}")
    @mms.process
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
    assert_nil @mms.subject
  end

end
