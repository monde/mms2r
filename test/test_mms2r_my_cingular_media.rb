$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2R::MyCingularMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image
    mail = TMail::Mail.parse(load_mail('mycingular-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::MyCingularMedia, mms.class, "expected a #{MMS2R::MyCingularMedia} and received a #{mms.class}")
    mms.process
    
    assert_equal 2, mms.media.size, "Size is #{mms.media.size}"
    assert_not_nil mms.media['text/plain']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/04-18-07_1723.jpg$/, mms.media['image/jpeg'][0])
    
    assert_equal nil, mms.subject, "Default Cingular subject not stripped"
    assert_file_size mms.media['image/jpeg'][0], 337

    assert_equal "Water", IO.readlines(mms.get_text.path).join
    
    mms.purge
  end
end
