$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2RCingularTest < Test::Unit::TestCase

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teadown; end

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

  private
  def load_mail(file)
    IO.readlines("#{File.dirname(__FILE__)}/files/#{file}")
  end
end
