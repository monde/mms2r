$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'yaml'
require 'fileutils'
require 'mms2r'
require 'tmail/mail'
require 'logger'

class MMS2R::MediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  class MMS2R::FakeCarrier < MMS2R::Media; end

  JENNYSNUMER = '2068675309'
  GENERIC_CARRIER = 'mms.example.com'

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
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    FileUtils.rm_rf(@confdir)
    MMS2R::Media.tmp_dir = @oldtmpdir
    MMS2R::Media.conf_dir = @oldconfdir
  end

  def test_version
    assert MMS2R::Media::VERSION > '0.0.1'
  end

  def test_collect_text_multipart_alternative
    mail = TMail::Mail.parse(load_mail('simple_multipart_alternative.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['text/plain']
    assert_equal 3, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['text/html'].size
    assert_equal 1, mms.media['image/gif'].size

    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "This is an MMS message.  Hello World.", text
    mms.purge
  end

  def test_collect_simple_image
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['image/gif']
    assert_equal 1, mms.media.size
    file = mms.media['image/gif'].first
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    assert File.basename(file) =~ /spacer\.gif/, "file #{file} does not exist"
    mms.purge
  end

  def test_collect_simple_image_using_block
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    mms = MMS2R::Media.create(mail)
    file_array = nil
    mms.process do |k, v|
      file_array = v if (k == 'image/gif')
      assert_not_nil(file = file_array.first)
      assert(File::exist?(file), "file #{file} does not exist")
      assert(File.basename(file) =~ /spacer\.gif/, "file #{file} does not exist")
    end
    # mms.purge has to be called manually 
    assert File.exist?(file_array.first)
  end

  def test_collect_text_plain
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media.size
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "hello world", text
    mms.purge
  end

  def test_collect_text_multi
    mail = TMail::Mail.parse(load_mail('hello_world_mail_multipart.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['text/plain']
    assert_not_nil mms.media['application/smil']
    assert_equal 2, mms.media.size
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "hello world", text
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
    assert File::exist?(file), "file #{file} does not exist"
    mms.purge
    assert !File::exist?(file), "file #{file} should not exist!"
  end

  def test_custom_media_carrier
    cls = MMS2R::FakeCarrier
    host = 'mms.fakecarrier.com'
    MMS2R::CARRIER_CLASSES[host] = cls
    mail = TMail::Mail.new
    mail.from = ["#{JENNYSNUMER}@#{host}"]
    mms = MMS2R::Media.create(mail)
    assert_equal cls, mms.class, "expected a #{cls} and received a #{mms.class}"
  end

  def test_create
    MMS2R::CARRIER_CLASSES.each do |car, cls|
      mail = TMail::Mail.new
      mail.from = ["#{JENNYSNUMER}@#{car}"]
      mms = MMS2R::Media.create(mail)
      assert_equal cls, mms.class, "expected a #{cls} and received a #{mms.class}"
      mms = MMS2R::Media.create(mail)
      assert_equal cls, mms.class, "expected a #{cls} and received a #{mms.class}"
      assert_equal car, mms.carrier, "expected a #{car} and received a #{mms.carrier}"
    end
  end

  def test_logging
    MMS2R::CARRIER_CLASSES.each do |car, cls|
      mail = TMail::Mail.new
      mail.from = ["#{JENNYSNUMER}@#{car}"]
      mms = MMS2R::Media.create(mail,@log)
      assert_equal cls, mms.class, "expected a #{cls} and received a #{mms.class}"
    end
  end

  def test_tmp_dir
    use_temp_dirs()
    MMS2R::Media.tmp_dir = @tmpdir
    assert MMS2R::Media.tmp_dir.eql?(@tmpdir)
  end

  def test_conf_dir
    use_temp_dirs()
    MMS2R::Media.conf_dir = @confdir
    assert MMS2R::Media.conf_dir.eql?(@confdir)
  end

  def test_transform_text
    use_temp_dirs()
    t={"hello world" => "foo bar"}
    h={'text/plain' => t}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_transform.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "foo bar", text
    mms.purge
  end

  def test_transform_text_for_application_smil
    use_temp_dirs()
    t={"Water" => "Juice"}
    h={'application/smil' => t}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_transform.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mail = TMail::Mail.parse(load_mail('hello_world_mail_multipart.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_not_nil mms.media['application/smil']
    file = mms.media['application/smil'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "Juice", text
    mms.purge
  end

  def test_mms_with_two_images_should_get_media_to_largest_file
    mail = TMail::Mail.parse(load_mail('simple-with-two-images-two-texts.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    file = mms.get_media
    assert_equal 'big.jpg', file.original_filename
    mms.purge
  end

  def test_mms_with_two_texts_should_get_text_to_largest_file
    mail = TMail::Mail.parse(load_mail('simple-with-two-images-two-texts.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    file = mms.get_text
    assert_equal 'big.txt', file.original_filename
    mms.purge
  end

  def test_mms_should_have_a_phone_number
    mail = TMail::Mail.parse(load_mail('hello_world_empty_text.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal '2068675309', mms.get_number
    mms.purge
  end

  def test_transform_text_should_ignore_empty_text_parts
    mail = TMail::Mail.parse(load_mail('hello_world_empty_text.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal 0, mms.media.size
    mms.purge
  end

  def test_ignore_text
    use_temp_dirs()
    a=[/^hello world$/]
    h={'text/plain' => a}
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media_ignore.yml')
    File.open(f, 'w') do |out|
      YAML.dump(h, out)
    end
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert mms.media['text/plain'].nil?
    assert_equal 0, mms.media.size
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
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert mms.media['image/gif'].nil?
    assert_equal 0, mms.media.size
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
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal 1, mms.media['image/gif'].size
    assert_equal 1, mms.media.size
    mms.purge
  end

  def test_safe_message_id
    mid1_b="1234abcd"
    mid1_a="1234abcd"
    mid2_b="<01234567.0123456789012.JavaMail.fooba@foo-bars999>"
    mid2_a="012345670123456789012JavaMailfoobafoo-bars999"
    assert MMS2R::Media.safe_message_id(mid1_b).eql?(mid1_a)
    assert MMS2R::Media.safe_message_id(mid2_b).eql?(mid2_a)
  end

  def default_ext
    assert MMS2R::Media.default_ext('text').nil?
    assert MMS2R::Media.default_ext('text/plain').eql?('plain')
    assert MMS2R::Media.default_ext('image/jpeg').eql?('jpeg')
    assert MMS2R::Media.default_ext('video/mp4').eql?('mp4')
  end

  def test_part_type
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    assert MMS2R::Media.part_type?(mail).eql?('text/plain')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_with_content_type.mail').join)
    assert MMS2R::Media.part_type?(mail).eql?('text/plain')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_multipart.mail').join)
    assert MMS2R::Media.part_type?(mail.parts[0]).eql?('text/plain')
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    assert MMS2R::Media.part_type?(mail.parts[0]).eql?('image/gif')
  end

  def test_main_type
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    assert MMS2R::Media.main_type?(mail).eql?('text')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_with_content_type.mail').join)
    assert MMS2R::Media.main_type?(mail).eql?('text')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_multipart.mail').join)
    assert MMS2R::Media.main_type?(mail.parts[0]).eql?('text')
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    assert MMS2R::Media.main_type?(mail.parts[0]).eql?('image')
  end

  def test_sub_type
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    assert MMS2R::Media.sub_type?(mail).eql?('plain')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_with_content_type.mail').join)
    assert MMS2R::Media.sub_type?(mail).eql?('plain')
    mail = TMail::Mail.parse(load_mail('hello_world_mail_multipart.mail').join)
    assert MMS2R::Media.sub_type?(mail.parts[0]).eql?('plain')
    mail = TMail::Mail.parse(load_mail('simple_image.mail').join)
    assert MMS2R::Media.sub_type?(mail.parts[0]).eql?('gif')
  end

  def test_get_subject
    subjects = [nil, '', '(no subject)']

    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    subjects.each do |s|  
      mail.subject = s
      mms = MMS2R::Media.create(mail)
      mms.process
      assert_equal nil, mms.get_subject, "Default subject not scrubbed."
      mms.purge
    end

    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal 'text only', mms.get_subject
    mms.purge
  end
  
  def test_get_body
    mail = TMail::Mail.parse(load_mail('hello_world_mail_plain_no_content_type.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal 'hello world', mms.get_body
    mms.purge
  end

  def test_yaml_file_name
    assert_equal 'mms2r_my_cingular_media_subject.yml', MMS2R::Media.yaml_file_name(MMS2R::MyCingularMedia,:subject)
    assert_equal 'mms2r_t_mobile_media_subject.yml', MMS2R::Media.yaml_file_name(MMS2R::TMobileMedia,:subject)
    assert_equal 'mms2r_media_ignore.yml', MMS2R::Media.yaml_file_name(MMS2R::MyCingularMedia.superclass,:ignore)
    assert_equal 'mms2r_media_transform.yml', MMS2R::Media.yaml_file_name(MMS2R::Media,:transform)
  end
end
