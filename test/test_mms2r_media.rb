$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'test/unit'
require 'rubygems'
require 'yaml'
require 'fileutils'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RMediaTest < Test::Unit::TestCase

  class MMS2R::FakeCarrier < MMS2R::Media; end

  JENNYSNUMER = '2068675309'
  GENERIC_CARRIER = 'mms.example.com'

  CARRIER_TO_CLASS = {
    'unknowncarrier.tld' => MMS2R::Media,
    'mmode.com' => MMS2R::MModeMedia,
    'mms.mycingular.com' => MMS2R::CingularMedia,
    'pm.sprint.com' => MMS2R::SprintMedia,
    'messaging.sprintpcs.com' => MMS2R::SprintMedia,
    'tmomail.net' => MMS2R::TMobileMedia,
    'vzwpix.com' => MMS2R::VerizonMedia
  }

  def use_temp_dirs
    MMS2R::Media.tmp_dir = @tmpdir
    MMS2R::Media.conf_dir = @confdir
  end

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"

    @tmpdir = File.join(Dir.tmpdir, "#{Time.now.to_i}-t")
    FileUtils.mkdir_p(@tmpdir)
    @confdir = File.join(Dir.tmpdir, "#{Time.now.to_i}-c")
    FileUtils.mkdir_p(@confdir)

    @oldtmpdir = MMS2R::Media.tmp_dir
    @oldconfdir = MMS2R::Media.conf_dir

    msg = <<EOF
From:2068675309@mms.example.com
To:tommytutone@example.com
Subject: text only
Message-Id: <00000000000001.0123456789@mx.mms.example.com>
Date: Wed, 10 Jan 2007 08:18:30 -0600 (CST)

hello world
EOF
    @hello_world_mail_plain_no_content_type = TMail::Mail.parse(msg)

    msg = <<EOF
From:2068675309@mms.example.com
To:tommytutone@example.com
Subject: text only
Message-Id: <00000000000001.0123456789@mx.mms.example.com>
Content-Type: text/plain; charset=utf-8
Date: Wed, 10 Jan 2007 08:18:30 -0600 (CST)

hello world
EOF
    @hello_world_mail_plain_with_content_type = TMail::Mail.parse(msg)

    msg = <<EOF
Message-Id: <00000000000002.0123456789@mx.mms.example.com>
Mime-Version: 1.0
From: 2068675309@mms.example.com
To: tommytutone@example.com
Subject: text only
Date: Thu, 11 Jan 2007 02:28:22 -0500
Content-Type: multipart/mixed;  boundary="----=_Part_1061064_5544954.1168500502466"

------=_Part_1061064_5544954.1168500502466
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: base64
Content-Location: hello_world.txt
Content-Disposition: inline

aGVsbG8gd29ybGQ=
------=_Part_1061064_5544954.1168500502466--

EOF
    @hello_world_mail_multi = TMail::Mail.parse(msg)

    msg = <<EOF
Mime-Version: 1.0
Message-Id: <00000000000001.0123456789@mx.mms.example.com>
Date: Sun, 29 Oct 2006 20:40:30 -0800 (PST)
To: tommytutone@example.com
From: 2068675309@mms.example.com
Subject: image test
Content-Type: multipart/related; type="multipart/alternative";
	boundary="----=_Part_1224755_98719.1162204830872"; start="<SMIL.TXT>"
X-Mms-Delivery-Report: no

------=_Part_1224755_98719.1162204830872
Content-Type: image/gif; name=spacer.gif
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=spacer.gif
Content-ID: <spacer.gif>

R0lGODlhAQABAIAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==
------=_Part_1224755_98719.1162204830872--

EOF
    @simple_image_mail = TMail::Mail.parse(msg)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    FileUtils.rm_rf(@confdir)
    MMS2R::Media.tmp_dir = @oldtmpdir
    MMS2R::Media.conf_dir = @oldconfdir
  end

  def test_collect_simple_image
    mms = MMS2R::Media.create(@simple_image_mail)
    mms.process
    assert_not_nil(mms.media['image/gif'])
    file = mms.media['image/gif'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    assert(File.basename(file) =~ /spacer\.gif/, "file #{file} does not exist")
    mms.purge
  end

  def test_collect_text_plain
    mms = MMS2R::Media.create(@hello_world_mail_plain_no_content_type)
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

  def test_collect_text_multi
    mms = MMS2R::Media.create(@hello_world_mail_multi)
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end

  def test_purge
    mail = TMail::Mail.new
    mail.message_id = TMail.new_message_id
    mail.from = ["#{JENNYSNUMER}@#{GENERIC_CARRIER}"]
    mail.body = "hello world"
    mms = MMS2R::Media.create(mail)
    mms.process
    file = mms.media['text/plain'][0]
    assert(File::exist?(file), "file #{file} does not exist")
    mms.purge
    assert(!File::exist?(file), "file #{file} should not exist!")
  end

  def test_custom_media_carrier
    cls = MMS2R::FakeCarrier
    host = 'mms.fakecarrier.com'
    MMS2R::CARRIER_CLASSES[host] = cls
    mail = TMail::Mail.new
    mail.from = ["#{JENNYSNUMER}@#{host}"]
    mms = MMS2R::Media.create(mail)
    assert_equal(cls, mms.class, "expected a #{cls} and received a #{mms.class}")
  end

  def test_create
    CARRIER_TO_CLASS.each {|car, cls|
      mail = TMail::Mail.new
      mail.from = ["#{JENNYSNUMER}@#{car}"]
      mms = MMS2R::Media.create(mail)
      assert_equal(cls, mms.class, "expected a #{cls} and received a #{mms.class}")
      mms = MMS2R::Media.create(mail)
      assert_equal(cls, mms.class, "expected a #{cls} and received a #{mms.class}")
    }
  end

  def test_logging
    CARRIER_TO_CLASS.each {|car, cls|
      mail = TMail::Mail.new
      mail.from = ["#{JENNYSNUMER}@#{car}"]
      mms = MMS2R::Media.create(mail,@log)
      assert_equal(cls, mms.class, "expected a #{cls} and received a #{mms.class}")
    }
  end

  def test_tmp_dir
    use_temp_dirs()
    MMS2R::Media.tmp_dir = @tmpdir
    assert(MMS2R::Media.tmp_dir.eql?(@tmpdir))
  end

  def test_conf_dir
    use_temp_dirs()
    MMS2R::Media.conf_dir = @confdir
    assert(MMS2R::Media.conf_dir.eql?(@confdir))
  end

  def test_transform_text
    use_temp_dirs()
    t={"hello world" => "foo bar"}
    h={'text/plain' => t}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_transform.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mms = MMS2R::Media.create(@hello_world_mail_plain_no_content_type)
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/foo bar/, text)
    mms.purge
  end

  def test_ignore_text
    use_temp_dirs()
    a=["hello world"]
    h={'text/plain' => a}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_ignore.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mms = MMS2R::Media.create(@hello_world_mail_plain_no_content_type)
    mms.process
    assert(mms.media['text/plain'].nil?)
    assert(mms.media.size == 0)
    mms.purge
  end

  def test_ignore_media
    use_temp_dirs()
    a=["spacer.gif"]
    h={'image/gif' => a}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_ignore.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mms = MMS2R::Media.create(@simple_image_mail)
    mms.process
    assert(mms.media['image/gif'].nil?)
    assert(mms.media.size == 0)
    mms.purge
  end

  def test_when_ignore_media_does_nothing
    use_temp_dirs()
    a=["foo.gif"]
    h={'image/gif' => a}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_ignore.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mms = MMS2R::Media.create(@simple_image_mail)
    mms.process
    assert(mms.media['image/gif'].size == 1)
    assert(mms.media.size == 1)
    mms.purge
  end

  def test_safe_message_id
    mid1_b="1234abcd"
    mid1_a="1234abcd"
    mid2_b="<01234567.0123456789012.JavaMail.fooba@foo-bars999>"
    mid2_a="012345670123456789012JavaMailfoobafoo-bars999"
    assert(MMS2R::Media.safe_message_id(mid1_b).eql?(mid1_a))
    assert(MMS2R::Media.safe_message_id(mid2_b).eql?(mid2_a))
  end

  def default_ext
    assert(MMS2R::Media.default_ext('text').nil?)
    assert(MMS2R::Media.default_ext('text/plain').eql?('plain'))
    assert(MMS2R::Media.default_ext('image/jpeg').eql?('jpeg'))
    assert(MMS2R::Media.default_ext('video/mp4').eql?('mp4'))
  end

  def test_part_type
    assert(MMS2R::Media.part_type?(@hello_world_mail_plain_no_content_type).eql?('text/plain'))
    assert(MMS2R::Media.part_type?(@hello_world_mail_plain_with_content_type).eql?('text/plain'))
    assert(MMS2R::Media.part_type?(@hello_world_mail_multi.parts[0]).eql?('text/plain'))
    assert(MMS2R::Media.part_type?(@simple_image_mail.parts[0]).eql?('image/gif'))
  end

  def test_main_type
    assert(MMS2R::Media.main_type?(@hello_world_mail_plain_no_content_type).eql?('text'))
    assert(MMS2R::Media.main_type?(@hello_world_mail_plain_with_content_type).eql?('text'))
    assert(MMS2R::Media.main_type?(@hello_world_mail_multi.parts[0]).eql?('text'))
    assert(MMS2R::Media.main_type?(@simple_image_mail.parts[0]).eql?('image'))
  end

  def test_sub_type
    assert(MMS2R::Media.sub_type?(@hello_world_mail_plain_no_content_type).eql?('plain'))
    assert(MMS2R::Media.sub_type?(@hello_world_mail_plain_with_content_type).eql?('plain'))
    assert(MMS2R::Media.sub_type?(@hello_world_mail_multi.parts[0]).eql?('plain'))
    assert(MMS2R::Media.sub_type?(@simple_image_mail.parts[0]).eql?('gif'))
  end
end
