$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RMModeTest < Test::Unit::TestCase

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"

    msg = <<EOF
Message-ID: <0000000.0000000000001.JavaMail.faalala@lalalala03>
Mime-Version: 1.0
From: 12068675309@mmode.com
To: tommytutone@example.com
Date: Thu, 11 Jan 2007 02:28:22 -0500
Subject: image test
Content-Type: multipart/related; type="multipart/alternative";
	boundary="----=_Part_1224755_98719.1162204830872"; start="<SMIL.TXT>"
X-Mms-Delivery-Report: no

------=_Part_1224755_98719.1162204830872
Content-Type: image/gif; name=foo.gif
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=foo.gif
Content-ID: <foo.gif>

R0lGODlhAQABAIAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==
------=_Part_1224755_98719.1162204830872--

EOF
    @simple_image_mail = TMail::Mail.parse(msg)
  end

  def teadown; end

  def test_simple
    mms = MMS2R::Media.create(@simple_image_mail)
    assert_equal(MMS2R::MModeMedia, mms.class, "expected a #{MMS2R::MModeMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['image/gif'])   
    file = mms.media['image/gif'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    mms.purge
  end
end
