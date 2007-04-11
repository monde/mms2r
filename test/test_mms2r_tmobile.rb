$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RTMobileTest < Test::Unit::TestCase

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teardown; end

  def test_ignore_simple_image
    mail = TMail::Mail.parse(load_mail('tmobile-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/12-01-06_1234.jpg$/, mms.media['image/jpeg'][0])

    file = mms.media['image/jpeg'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File::size(file) == 337, "file #{file} not 337 byts")

    mms.purge
  end
  
  def test_message_with_body_text
    mail = TMail::Mail.parse(load_mail('tmobile-image-02.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    
    assert(mms.media.size == 2)
    assert_not_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/07-25-05_0935.jpg$/, mms.media['image/jpeg'][0])
    
    file = mms.media['image/jpeg'][0]
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File::size(file) == 337, "file #{file} is not 337 bytes")
    
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_equal "Lillies", text.strip
    
    mms.purge
  end

  private
  def load_mail(file)
    IO.readlines("#{File.dirname(__FILE__)}/files/#{file}")
  end
end
