# encoding: UTF-8

require "test_helper"

class TestMms2rMedia < Test::Unit::TestCase
  include MMS2R::TestHelper

  def use_temp_dirs
    MMS2R::Media.tmp_dir = @tmpdir
    MMS2R::Media.conf_dir = @confdir
  end

  def setup
    @oldtmpdir = MMS2R::Media.tmp_dir || File.join(Dir.tmpdir, "#{Time.now.to_i}-#{rand(1000)}")
    @oldconfdir = MMS2R::Media.conf_dir || File.join(Dir.tmpdir, "#{Time.now.to_i}-#{rand(1000)}")
    FileUtils.mkdir_p(@oldtmpdir)
    FileUtils.mkdir_p(@oldconfdir)

    @tmpdir = File.join(Dir.tmpdir, "#{Time.now.to_i}-#{rand(1000)}")
    FileUtils.mkdir_p(@tmpdir)
    @confdir = File.join(Dir.tmpdir, "#{Time.now.to_i}-#{rand(1000)}")
    FileUtils.mkdir_p(@confdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    FileUtils.rm_rf(@confdir)
    MMS2R::Media.tmp_dir = @oldtmpdir
    MMS2R::Media.conf_dir = @oldconfdir
  end

  def stub_mail(vals = {})
    attrs = {
         :from => 'joe@example.com',
         :to => 'jane@example.com',
         :subject => 'This is a test email',
         :body => 'a',
        }.merge(vals)

    Mail.new do
      from attrs[:from]
      to attrs[:to]
      subject attrs[:subject]
      body attrs[:body]
    end
  end

  def test_faux_user_agent
    assert_equal "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.120 Safari/535.2",  MMS2R::Media::USER_AGENT
  end

  def test_class_parse
    mms = mail('generic.mail')
    assert_equal ['noreply@rubyforge.org'], mms.from
  end

  def temp_text_file(text)
    tf = Tempfile.new("test" + rand.to_s)
    tf.puts(text)
    tf.close
    tf.path
  end

  def test_tmp_dir
    use_temp_dirs()
    MMS2R::Media.tmp_dir = @tmpdir
    assert_equal @tmpdir, MMS2R::Media.tmp_dir
  end

  def test_conf_dir
    use_temp_dirs()
    MMS2R::Media.conf_dir = @confdir
    assert_equal @confdir, MMS2R::Media.conf_dir
  end

  def test_safe_message_id
    mid1_b="1234abcd"
    mid1_a="1234abcd"
    mid2_b="<01234567.0123456789012.JavaMail.fooba@foo-bars999>"
    mid2_a="012345670123456789012JavaMailfoobafoo-bars999"
    assert_equal mid1_a, MMS2R::Media.safe_message_id(mid1_b)
    assert_equal mid2_a, MMS2R::Media.safe_message_id(mid2_b)
  end

  def test_default_ext
    assert_equal nil, MMS2R::Media.default_ext(nil)
    assert_equal 'text', MMS2R::Media.default_ext('text')
    assert_equal 'txt', MMS2R::Media.default_ext('text/plain')
    assert_equal 'test', MMS2R::Media.default_ext('example/test')
  end

  def test_base_initialize_config_tries_to_open_default_config_yaml
    f = File.join(MMS2R::Media.conf_dir, 'mms2r_media.yml')
    YAML.expects(:load_file).once.with(f).returns({})
    config = MMS2R::Media.initialize_config(nil)
  end

  def test_base_initialize_config
    config = MMS2R::Media.initialize_config(nil)

    # test defaults shipped in mms2r_media.yml
    assert_not_nil config
    assert_equal true, config['ignore'].is_a?(Hash)
    assert_equal true, config['transform'].is_a?(Hash)
    assert_equal true, config['number'].is_a?(Array)
  end

  def test_instance_initialize_config
    mms = MMS2R::Media.new stub_mail
    config = mms.initialize_config(nil)

    # test defaults shipped in mms2r_media.yml
    assert_not_nil config
    assert_equal true, config['ignore'].is_a?(Hash)
    assert_equal true, config['transform'].is_a?(Hash)
    assert_equal true, config['number'].is_a?(Array)
  end

  def test_initialize_config_contatenation
    c = {'ignore' => {'text/plain' => [/A TEST/]},
         'transform' => {'text/plain' => [/FOO/, '']},
         'number' => ['from', /^([^\s]+)\s.*/, '\1']
    }
    config = MMS2R::Media.initialize_config(c)
    assert_not_nil config['ignore']['text/plain'].detect{|v| v == /A TEST/}
    assert_not_nil config['transform']['text/plain'].detect{|v| v == /FOO/}
    assert_not_nil config['number'].first == 'from'
  end

  def test_aliased_new_returns_default_processor_instance
    mms = MMS2R::Media.new stub_mail
    assert_not_nil mms
    assert_equal true, mms.respond_to?(:process)
    assert_equal MMS2R::Media, mms.class
  end

  def test_lazy_process_option
    mms = MMS2R::Media.new stub_mail, :process => :lazy
    mms.expects(:process).never
  end

  def test_logger_option
    logger = mock()
    logger.expects(:info).at_least_once
    mms = MMS2R::Media.new stub_mail, :logger => logger
  end

  def test_default_processor_initialize_tries_to_open_config_for_carrier
    mms_yaml = File.expand_path(File.join(MMS2R::Media.conf_dir, 'mms2r_media.yml'))
    aliases_yaml = File.expand_path(File.join(MMS2R::Media.conf_dir, 'aliases.yml'))
    from_yaml = File.expand_path(File.join(MMS2R::Media.conf_dir, 'from.yml'))
    example_yaml = File.expand_path(File.join(MMS2R::Media.conf_dir, 'example.com.yml'))
    YAML.expects(:load_file).at_least_once.with(mms_yaml).returns({})
    YAML.expects(:load_file).at_least_once.with(aliases_yaml).returns({})
    YAML.expects(:load_file).at_least_once.with(from_yaml).returns([])
    YAML.expects(:load_file).never.with(example_yaml)
    mms = MMS2R::Media.new stub_mail
  end

  def test_mms_phone_number
    mail = stub_mail
    mail.stubs(:from).returns(['2068675309@example.com'])
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
  end

  def test_mms_phone_number_from_config
    mail = stub_mail(:from => '"+2068675309" <TESTER@mms.vodacom4me.co.za>')
    mms = MMS2R::Media.new(mail)
    mms.expects(:config).once.returns({'number' => ['from', /^([^\s]+)\s.*/, '\1']})
    assert_equal '+2068675309', mms.number
  end

  def test_mms_phone_number_with_errors
    mail = stub_mail
    mail.stubs(:from).returns(nil)
    mms = MMS2R::Media.new(mail)
    assert_nothing_raised do
      assert_equal '', mms.number
    end
  end

  def test_transform_text_plain
    mail = stub_mail
    mail.stubs(:from).returns(nil)
    mms = MMS2R::Media.new(mail)

    type = 'test/type'
    text = 'hello'

    # no match in the config
    result = [type, text]
    assert_equal result, mms.transform_text(type, text)

    # testing the default config
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "From my HTC Sensation 4G on T-Mobile. The first nationwide 4G network")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "Sent from my Windows Phone")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "Sent via BlackBerry from T-Mobile")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "Sent from my Verizon Wireless BlackBerry")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', 'Sent via iPhone')
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', 'Sent from my iPhone')
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', 'Sent from your iPhone.')
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', " \n\nimage/jpeg")

    # has a bad regexp
    mms.expects(:config).at_least_once.returns({'transform' => {type => [['(hello)', 'world']]}})
    assert_equal result, mms.transform_text(type, text)

    # matches in config
    mms.expects(:config).at_least_once.returns({'transform' => {type => [[/(hello)/, 'world']]}})
    assert_equal [type, 'world'], mms.transform_text(type, text)

    mms.expects(:config).at_least_once.returns({'transform' => {type => [[/^Ignore this part, (.+)/, '\1']]}})
    assert_equal [type, text], mms.transform_text(type, "Ignore this part, " + text)

    # chaining transforms
    mms.expects(:config).at_least_once.returns({'transform' => {type => [[/(hello)/, 'world'],
                                                                [/(world)/, 'mars']]}})
    assert_equal [type, 'mars'], mms.transform_text(type, text)

    # has a Iconv problem
    mms.expects(:config).at_least_once.returns({'transform' => {type => [['(hello)', 'world']]}})
    assert_equal result, mms.transform_text(type, text)
  end

  def test_transform_text_to_utf8
    mail = mail('iconv-fr-text-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['text/html'].size
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)
    if RUBY_VERSION < "1.9"
      text = IO.read("#{file}")
    else
      text = IO.read("#{file}", :mode => "rb")
    end

    # ASCII-8BIT -> D'ici un mois G\xE9orgie
    # UTF-8      -> D'ici un mois Géorgie

    assert_equal("sample email message Fwd: sub D'ici un mois Géorgie", mms.subject)
  end

  def test_subject
    s = 'hello world'
    mail = stub_mail
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    assert_equal s, mms.subject

    # second time through shouldn't process the subject again
    mail.expects(:subject).never
    assert_equal s, mms.subject
  end

  def test_subject_with_bad_mail_subject
    mail = stub_mail
    mail.stubs(:subject).returns(nil)
    mms = MMS2R::Media.new(mail)
    assert_equal '', mms.subject
  end

  def test_subject_with_subject_ignored
    s = 'hello world'
    mail = stub_mail
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    mms.stubs(:config).returns({'ignore' => {'text/plain' => [s]}})
    assert_equal '', mms.subject
  end

  def test_subject_with_subject_transformed
    s = 'Default Subject: hello world'
    mail = stub_mail
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    mms.stubs(:config).returns(
      { 'ignore' => {},
        'transform' => {'text/plain' => [[/Default Subject: (.+)/, '\1']]}})
    assert_equal 'hello world', mms.subject
  end

  def test_attachment_should_return_nil_if_files_for_type_are_not_found
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:media).returns({})
    assert_nil mms.send(:attachment, ['text'])
  end

  def test_attachment_should_return_nil_if_empty_files_are_found
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:media).returns({'text/plain' => [Tempfile.new('test')]})
    assert_nil mms.send(:attachment, ['text'])
  end

  def test_type_from_filename
    mms = MMS2R::Media.new stub_mail
    assert_equal 'image/jpeg', mms.send(:type_from_filename, "example.jpg")
  end

  def test_type_from_filename_should_be_nil
    mms = MMS2R::Media.new stub_mail
    assert_nil mms.send(:type_from_filename, "example.example")
  end

  def test_attachment_should_return_duck_typed_file
    mms = MMS2R::Media.new stub_mail
    duck_file = mms.send(:attachment, ['text'])
    assert_equal 1, duck_file.size
    assert_equal 'text/plain', duck_file.content_type
    assert_equal "a", open(mms.media['text/plain'].first).read
  end

  def test_empty_body
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:default_text).returns(nil)
    assert_equal "", mms.body
  end

  def test_body
    mms = MMS2R::Media.new stub_mail
    temp_big = temp_text_file("hello world")
    mms.stubs(:default_text).returns(File.new(temp_big))
    body = mms.body
    assert_equal "hello world", body
  end

  def test_body_when_html
    mms = MMS2R::Media.new stub_mail(:body => '')
    temp_big = temp_text_file("<html><head><title>hello</title></head><body><p>world</p><p>teapot</p><body></html>")
    mms.stubs(:default_html).returns(File.new(temp_big))
    assert_equal "hello world teapot", mms.body
  end

  def test_default_text
    mms = MMS2R::Media.new stub_mail
    temp_big = temp_text_file("hello world")
    temp_small = temp_text_file("hello")
    mms.stubs(:media).returns({'text/plain' => [temp_small, temp_big]})

    assert_equal temp_big, mms.default_text.local_path

    # second time through shouldn't setup the @default_text by calling attachment
    mms.expects(:attachment).never
    assert_equal temp_big, mms.default_text.local_path
  end

  def test_default_html
    mms = MMS2R::Media.new stub_mail(:body => '')
    temp_big = temp_text_file("<html><head><title>hello</title></head><body><p>world</p><p>teapot</p><body></html>")
    temp_small = temp_text_file("<html><head><title>hello</title></head><body>world<body></html>")
    mms.stubs(:media).returns({'text/html' => [temp_small, temp_big]})

    assert_equal temp_big, mms.default_html.local_path

    # second time through shouldn't setup the @default_text by calling attachment
    mms.expects(:attachment).never
    assert_equal temp_big, mms.default_html.local_path
  end

  def test_default_media
    mms = MMS2R::Media.new stub_mail
    #it doesn't matter that these are text files, we just need say they are images
    temp_big = temp_text_file("hello world")
    temp_small = temp_text_file("hello")
    mms.stubs(:media).returns({'image/jpeg' => [temp_small, temp_big]})

    assert_equal temp_big, mms.default_media.local_path

    # second time through shouldn't setup the @default_media by calling attachment
    mms.expects(:attachment).never
    assert_equal temp_big, mms.default_media.local_path
  end

  def test_default_media_treats_image_and_video_equally
    mms = MMS2R::Media.new stub_mail
    #it doesn't matter that these are text files, we just need say they are images
    temp_big_image = temp_text_file("hello world")
    temp_small_image = temp_text_file("hello")
    temp_big_video = temp_text_file("hello world again")
    temp_small_video = temp_text_file("hello again")
    mms.stubs(:media).returns({'image/jpeg' => [temp_small_image, temp_big_image],
                               'video/mpeg' => [temp_small_video, temp_big_video],
    })

    assert_equal temp_big_video, mms.default_media.local_path

    # second time through shouldn't setup the @default_media by calling attachment
    mms.expects(:attachment).never
    assert_equal temp_big_video, mms.default_media.local_path
  end

  #def test_default_media_treats_gif_and_jpg_equally
  #  #it doesn't matter that these are text files, we just need say they are images
  #  temp_big = temp_text_file("hello world")
  #  temp_small = temp_text_file("hello")

  #  mms = MMS2R::Media.new stub_mail
  #  mms.stubs(:media).returns({'image/jpeg' => [temp_big], 'image/gif' => [temp_small]})
  #  assert_equal temp_big, mms.default_media.local_path

  #  mms = MMS2R::Media.new stub_mail
  #  mms.stubs(:media).returns({'image/gif' => [temp_big], 'image/jpg' => [temp_small]})
  #  assert_equal temp_big, mms.default_media.local_path
  #end

  def test_purge
    mms = MMS2R::Media.new stub_mail
    mms.purge
    assert_equal false, File.exist?(mms.media_dir)
  end

  def test_ignore_media_by_filename_equality
    name = 'foo.txt'
    type = 'text/plain'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:config).returns({'ignore' => {type => [name]}})

    # type is not in the ingore
    part = stub(:body => Mail::Body.new('a'))
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and filename are in the ingore
    part = stub(:filename => name, :body => Mail::Body.new('a'))
    assert_equal true, mms.ignore_media?(type, part)
    # type but not file name are in the ignore
    part = stub(:filename => 'bar.txt', :body => Mail::Body.new('a'))
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_filename
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name)
    assert_equal 'foo.txt', mms.filename?(part)
  end

  def test_long_filename
    name = 'x' * 300 + '.txt'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name)
    assert_equal 'x' * 251 + '.txt', mms.filename?(part)
  end

  def test_filename_when_file_extension_missing_part
    name = 'foo'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name, :content_type => 'text/plain', :part_type? => 'text/plain')
    assert_equal 'foo.txt', mms.filename?(part)

    name = 'foo.janky'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name, :content_type => 'text/plain', :part_type? => 'text/plain')
    assert_equal 'foo.janky.txt', mms.filename?(part)
  end

  def test_ignore_media_by_filename_regexp
    name = 'foo.txt'
    regexp = /foo\.txt/i
    type = 'text/plain'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:config).returns({'ignore' => {type => [regexp, 'nil.txt']}})

    # type is not in the ingore
    part = stub(:filename => name, :body => Mail::Body.new('a'))
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and regexp for the filename are in the ingore
    part = stub(:filename => name)
    assert_equal true, mms.ignore_media?(type, part)
    # type but not regexp for filename are in the ignore
    part = stub(:filename => 'bar.txt', :body => Mail::Body.new('a'))
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_ignore_media_by_regexp_on_file_content
    name = 'foo.txt'
    content = "aaaaaaahello worldbbbbbbbbb"
    regexp = /.*Hello World.*/i
    type = 'text/plain'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:config).returns({'ignore' => {type => ['nil.txt', regexp]}})

    part = stub(:filename => name, :body => Mail::Body.new(content))

    # type is not in the ingore
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and regexp for the content are in the ingore
    assert_equal true, mms.ignore_media?(type, part)
    # type but not regexp for content are in the ignore
    part = stub(:filename => name, :body => Mail::Body.new('no teapots'))
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_ignore_media_when_file_content_is_empty
    mms = MMS2R::Media.new stub_mail

    # there is no conf but the part's body is empty
    part = stub(:filename => 'foo.txt', :body => Mail::Body.new)
    assert_equal true, mms.ignore_media?('text/test', part)

    # there is no conf but the part's body is white space
    part = stub(:filename => 'foo.txt', :body => Mail::Body.new("\t\n\t\n            "))
    assert_equal true, mms.ignore_media?('text/test', part)
  end

  def test_add_file
    mail = stub_mail
    mail.stubs(:from).returns(['joe@null.example.com'])

    mms = MMS2R::Media.new(mail)
    mms.stubs(:media).returns({})

    assert_nil mms.media['text/html']
    mms.add_file('text/html', '/tmp/foo.html')
    assert_equal ['/tmp/foo.html'], mms.media['text/html']
    mms.add_file('text/html', '/tmp/bar.html')
    assert_equal ['/tmp/foo.html', '/tmp/bar.html'], mms.media['text/html']
  end

  def test_temp_file
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name)
    assert_equal name, File.basename(mms.temp_file(part))
  end

  def test_process_media_for_text
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:transform_text_part).returns(['text/plain', nil])
    part = stub(:filename => name, :content_type => 'text/plain', :part_type? => 'text/plain', :main_type => 'text')

    assert_equal ['text/plain', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['text/plain', 'hello world'])
    result = mms.process_media(part)
    assert_equal 'text/plain', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_with_empty_text
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:transform_text_part).returns(['text/plain', nil])
    part = stub(:filename => name, :content_type => 'text/plain', :part_type? => 'text/plain', :main_type => 'text')

    assert_equal ['text/plain', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['text/plain', ''])
    assert_equal ['text/plain', nil], mms.process_media(part)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_application_smil
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    mms.stubs(:transform_text_part).returns(['application/smil', nil])
    part = stub(:filename => name, :content_type => 'application/smil', :part_type? => 'application/smil', :main_type => 'application')

    assert_equal ['application/smil', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['application/smil', 'hello world'])
    result = mms.process_media(part)
    assert_equal 'application/smil', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_application_octet_stream_when_image
    name = 'fake.jpg'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name, :content_type => 'application/octet-stream', :part_type? => 'application/octet-stream', :body => Mail::Body.new("data"), :main_type => 'application')
    result = mms.process_media(part)
    assert_equal 'image/jpeg', result.first
    assert_match(/fake\.jpg$/, result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_all_other_media
    name = 'foo.txt'
    mms = MMS2R::Media.new stub_mail
    part = stub(:filename => name, :main_type => 'faux', :part_type? => 'faux/text', :body => Mail::Body.new(nil))

    assert_equal ['faux/text', nil], mms.process_media(part)

    part = stub(:filename => name, :main_type => 'faux', :part_type? => 'faux/text', :body => Mail::Body.new('hello world'))
    result = mms.process_media(part)
    assert_equal 'faux/text', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process
    mms = MMS2R::Media.new stub_mail
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal true, File.exist?(mms.media['text/plain'].first)
    assert_equal 1, File.size(mms.media['text/plain'].first)
    mms.purge
  end

  def test_process_with_multipart_double_parts
    mail = mail('apple-double-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size

    assert_not_nil mms.media['application/applefile']
    assert_equal 1, mms.media['application/applefile'].size

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/DSCN1715\.jpg$/, mms.media['image/jpeg'].first)

    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end

  def test_folding_with_multipart_alternative_parts
    mail = mail('helio-message-01.mail')
    mms = MMS2R::Media.new(Mail.new)
    assert_equal 5, mms.send(:folded_parts, mail.parts).size
  end

  def test_process_when_media_is_ignored
    # TODO - I'd like to get away from mocks and test on real data, and
    # this is covered repeatedly for various samples from the carrier
  end

  def test_process_when_yielding_to_a_block
    mail = mail('att-image-01.mail')
    mms = MMS2R::Media.new(mail)
    mms.process do |type, files|
      assert_equal 1, files.size
      assert_equal true, type == 'image/jpeg'
      assert_equal true, File.basename(files.first) == 'Photo_12.jpg'
      assert_equal true, File::exist?(files.first)
    end
    mms.purge
  end

  def test_domain_from_return_path
    mail = mock()
    mail.expects(:from).at_least_once.returns([])
    mail.expects(:return_path).at_least_once.returns('joe@null.example.com')
    domain = MMS2R::Media.domain(mail)
    assert_equal 'null.example.com', domain
  end

  def test_domain_from_from
    mail = mock()
    mail.expects(:from).at_least_once.returns(['joe@null.example.com'])
    mail.expects(:return_path).at_least_once.returns('joe@null.example.com')
    domain = MMS2R::Media.domain(mail)
    assert_equal 'null.example.com', domain
  end

  def test_domain_from_from_yaml
    f = File.join(MMS2R::Media.conf_dir, 'from.yml')
    YAML.expects(:load_file).once.with(f).returns(['example.com'])
    mail = mock()
    mail.expects(:from).at_least_once.returns(['joe@example.com'])
    mail.expects(:return_path).at_least_once.returns('joe@null.example.com')
    domain = MMS2R::Media.domain(mail)
    assert_equal 'example.com', domain
  end

  def test_unknown_device_type
    mail = mail('generic.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal :unknown, mms.device_type?
    assert_equal false, mms.is_mobile?
  end

  def test_iphone_device_type_by_header
    iphones = ['att-iphone-01.mail',
               'iphone-image-01.mail']
    iphones.each do |iphone|
      mail = mail(iphone)
      mms = MMS2R::Media.new(mail)
      assert_equal :iphone, mms.device_type?, "fixture #{iphone} was not a iphone"
      assert_equal true, mms.is_mobile?
    end
  end

  def test_exif
    mail = smart_phone_mock
    mms = MMS2R::Media.new(mail)
    assert_equal 'iPhone', mms.exif.model
  end

  def test_iphone_device_type_by_exif
    mail = smart_phone_mock
    mms = MMS2R::Media.new(mail)
    assert_equal :iphone, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_faux_tiff_iphone_device_type_by_exif
    mail = smart_phone_mock('Apple', 'iPhone', nil, jpeg = false)
    mms = MMS2R::Media.new(mail)
    assert_equal :iphone, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_iphone_device_type_by_filename_jpg
    mail = smart_phone_mock('Hipstamatic', '201')
    mms = MMS2R::Media.new(mail)
    assert_equal :apple, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_iphone_device_type_by_filename_png
    mail = mail('iphone-image-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal true, mms.is_mobile?
    assert_equal :iphone, mms.device_type?
  end

  def test_blackberry_device_type_by_exif_make_model
    mail = smart_phone_mock('Research In Motion', 'BlackBerry')
    mms = MMS2R::Media.new(mail)
    assert_equal :blackberry, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_blackberry_device_type_by_exif_software
    mail = smart_phone_mock(nil, nil, "Rim Exif Version1.00a")
    mms = MMS2R::Media.new(mail)
    assert_equal :blackberry, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_dash_device_type_by_exif
    mail = smart_phone_mock('T-Mobile Dash', 'T-Mobile Dash')
    mms = MMS2R::Media.new(mail)
    assert_equal :dash, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_droid_device_type_by_exif
    mail = smart_phone_mock('Motorola', 'Droid')
    mms = MMS2R::Media.new(mail)
    assert_equal :droid, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_htc_eris_device_type_by_exif
    mail = smart_phone_mock('HTC', 'Eris')
    mms = MMS2R::Media.new(mail)
    assert_equal :htc, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_htc_hero_device_type_by_exif
    mail = smart_phone_mock('HTC', 'HERO200')
    mms = MMS2R::Media.new(mail)
    assert_equal :htc, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_android_app_by_exif
    mail = smart_phone_mock('Retro Camera Android', "Xoloroid 2000")
    mms = MMS2R::Media.new(mail)
    assert_equal :android, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

  def test_handsets_by_exif
    handsets = YAML.load_file(fixture('handsets.yml'))
    handsets.each do |handset|
      mail = smart_phone_mock(handset.first, handset.last)
      mms = MMS2R::Media.new(mail)
      assert_equal true, mms.is_mobile?, "mms with make #{mms.exif.make}, and model #{mms.exif.model}, should be considered a mobile device"
    end
  end

  def test_blackberry_device_type
    berries = ['att-blackberry.mail',
               'suncom-blackberry.mail',
               'tmobile-blackberry-02.mail',
               'tmobile-blackberry.mail',
               'tmo.blackberry.net-image-01.mail',
               'verizon-blackberry.mail',
               'verizon-blackberry.mail']
    berries.each do |berry|
      mms = MMS2R::Media.new(mail(berry))
      assert_equal :blackberry, mms.device_type?, "fixture #{berry} was not a blackberrry"
      assert_equal true, mms.is_mobile?
    end
  end

  def test_handset_device_type
    mail = mail('att-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal :handset, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

end
