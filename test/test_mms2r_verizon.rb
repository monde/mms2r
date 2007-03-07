$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RVerizonTest < Test::Unit::TestCase

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teadown; end

  def test_simple_video
    mail = TMail::Mail.parse(load_mail('verizon-video-01.mail').join)
    mms = MMS2R::Media.create(mail,@logger)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['video/3gpp2'][0])
    assert_match(/012345_67890.3g2$/, mms.media['video/3gpp2'][0])

    file = mms.media['video/3gpp2'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File::size(file) == 16553, "file #{file} not 16553 byts")
    mms.purge
  end

  def test_simple_image
    mail = TMail::Mail.parse(load_mail('verizon-image-01.mail').join)
    mms = MMS2R::Media.create(mail,@logger)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/IMAGE_00004.jpg$/, mms.media['image/jpeg'][0])

    file = mms.media['image/jpeg'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File::size(file) == 41983, "file #{file} not 41983 byts")
    mms.purge
  end

  def test_simple_text
    mail = TMail::Mail.parse(load_mail('verizon-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::VerizonMedia, mms.class, "expected a #{MMS2R::VerizonMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

  private
    def load_mail(file)
      IO.readlines("#{File.dirname(__FILE__)}/files/#{file}")
    end
end
