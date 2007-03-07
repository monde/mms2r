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

    msg = <<EOF
Message-ID: <0000000.0000000000001.JavaMail.faalala@lalalala03>
Mime-Version: 1.0
From: 2068675309@mms.mycingular.com
To: tommytutone@example.com
Subject: text with ad
Date: Thu, 11 Jan 2007 02:28:22 -0500

hello world

--
===============================================
Brought to you by, Cingular Wireless Messaging
http://www.CingularMe.COM/
 
EOF
    @text_sms_with_ad = TMail::Mail.parse(msg)
  end

  def teadown; end

  def test_clean_text_ad
    mms = MMS2R::Media.create(@text_sms_with_ad,@log)
    assert_equal(MMS2R::CingularMedia, mms.class, "expected a #{MMS2R::CingularMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    ad = "--\n===============================================\nBrought to you by, Cingular Wireless Messaging\nhttp://www.CingularMe.COM/ \n"
    assert_no_match(/#{ad}/m, text)
    good_text = "hello world\n\n"
    assert_match(/#{good_text}/m, text)
    mms.purge
  end
end
