$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RNextelTest < Test::Unit::TestCase

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teadown; end

  def test_simple_image
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/Jan15_0001.jpg$/, mms.media['image/jpeg'][0])

    file = mms.media['image/jpeg'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File::size(file) == 337, "file #{file} not 337 byts")

    mms.purge
  end

  private
  def load_mail(file)
    IO.readlines("#{File.dirname(__FILE__)}/files/#{file}")
  end
end
