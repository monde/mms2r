$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2RCingularTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teardown; end

  def test_clean_text_ad
    mail = TMail::Mail.parse(load_mail('cingularme-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::CingularMedia, mms.class, "expected a #{MMS2R::CingularMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    ad = "\n--\n===============================================\nBrought to you by, Cingular Wireless Messaging\nhttp://www.CingularMe.COM/"
    assert_no_match(/#{ad}/m, text)
    assert_no_match(/Brought to you by, Cingular Wireless Messaging/, text)
    good_text = "hello world\n\n"
    assert_match(/#{good_text}/m, text)
    mms.purge
  end
  
  def test_image
    mail = TMail::Mail.parse(load_mail('cingular-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::CingularMedia, mms.class, "expected a #{MMS2R::CingularMedia} and received a #{mms.class}")
    mms.process
    
    assert(mms.media.size == 2, "Size is #{mms.media.size}")
    assert_not_nil(mms.media['text/plain'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/04-18-07_1723.jpg$/, mms.media['image/jpeg'][0])
    
    assert_equal(nil, mms.get_subject, "Default Cingular subject not stripped")
    assert_file_size(mms.media['image/jpeg'][0], 337)

    assert_equal("Water", IO.readlines(mms.get_text.path).join)
    
    mms.purge
  end
end
