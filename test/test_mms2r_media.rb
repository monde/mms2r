require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'tempfile'
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestMms2rMedia < Test::Unit::TestCase
  include MMS2R::TestHelper

  class MMS2R::Media::NullCarrier < MMS2R::Media; end

  def use_temp_dirs
    MMS2R::Media.tmp_dir = @tmpdir
    MMS2R::Media.conf_dir = @confdir
  end

  def setup
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

  def stub_mail(*keys)
    attrs = { 
         :message_id => '123', 
         :from => ['joe@example.com'],
         :multipart? => false,
         :parts => [],
         :main_type => 'text',
         :content_type => 'text/plain',
         :part_type? => 'text/plain',
         :sub_header => 'message.txt',

         :body => 'a',
         :header => {}
        }.except(keys)
    stub('mail', attrs)
  end

  def temp_text_file(text)
    tf = Tempfile.new("test" + Time.now.to_f.to_s)
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

  def test_initialize_config_contatenation
    c = {'ignore' => {'text/plain' => ['/A TEST/']},
         'transform' => {'text/plain' => ['/FOO/', '']},
         'number' => ['from', '/^([^\s]+)\s.*/', '\1']
    }
    config = MMS2R::Media.initialize_config(c)
    assert_not_nil config['ignore']['text/plain'].detect{|v| v == '/A TEST/'}
    assert_not_nil config['transform']['text/plain'].detect{|v| v == '/FOO/'}
    assert_not_nil config['number'].first == 'from'
  end

  def test_create_with_default_processor
    mail = mock()
    mail.expects(:header).at_least_once.returns({})
    mail.expects(:from).at_least_once.returns(['joe@unknown.example.com'])
    mms = MMS2R::Media.create(mail)
    assert_equal [MMS2R::Media, 'unknown.example.com'] , mms
  end

  def test_create_with_special_processor
    MMS2R.register('null.example.com', MMS2R::Media::NullCarrier)
    mail = mock()
    mail.expects(:header).at_least_once.returns({})
    mail.expects(:from).at_least_once.returns(['joe@null.example.com'])
    mms = MMS2R::Media.create(mail)
    assert_equal [MMS2R::Media::NullCarrier, 'null.example.com'], mms
  end

  def test_create_with_special_processor_and_return_path
    MMS2R.register('null.example.com', MMS2R::Media::NullCarrier)
    mail = mock()
    mail.expects(:header).at_least_once.returns({'return-path' => '<joe@null.example.com>'})
    mail.expects(:from).at_least_once.returns([])
    mms = MMS2R::Media.create(mail)
    assert_equal [MMS2R::Media::NullCarrier, 'null.example.com'], mms
  end

  def test_create_should_fail_gracefully_with_broken_from
    mail = mock()
    mail.expects(:header).at_least_once.returns({})
    mail.expects(:from).at_least_once.returns(nil)
    assert_nothing_raised { MMS2R::Media.create(mail) }
  end

  def test_aliased_new_returns_custom_processor_instance
    MMS2R.register('null.example.com', MMS2R::Media::NullCarrier)
    mail = stub_mail(:from)
    mail.expects(:from).at_least_once.returns(['joe@null.example.com'])

    mms = MMS2R::Media.new(mail)
    assert_not_nil mms
    assert_equal MMS2R::Media::NullCarrier, mms.class
    assert_equal true, mms.respond_to?(:process)
  end

  def test_aliased_new_returns_default_processor_instance
    mms = MMS2R::Media.new(stub_mail())
    assert_not_nil mms
    assert_equal true, mms.respond_to?(:process)
    assert_equal MMS2R::Media, mms.class
  end

  def test_lazy_process_option
    mms = MMS2R::Media.new(stub_mail(), :process => :lazy)
    mms.expects(:process).never
  end

  def test_logger_option
    logger = mock()
    logger.expects(:info).at_least_once
    mms = MMS2R::Media.new(stub_mail(), :logger => logger)
  end

  def test_default_processor_initialize_tries_to_open_config_for_carrier
    f = File.join(MMS2R::Media.conf_dir, 'example.com.yml')
    YAML.expects(:load_file).once.with(f)
    mms = MMS2R::Media.new(stub_mail())
  end

  def test_mms_phone_number
    mail = stub_mail()
    mail.stubs(:from).returns(['2068675309@example.com'])
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
  end
  
  def test_mms_phone_number_from_config
    mail = stub_mail()
    mail.stubs(:header).returns({'from' => TMail::AddressHeader.new('from', '"+2068675309" <BCVOZH@mms.vodacom4me.co.za>')})
    mms = MMS2R::Media.new(mail)
    mms.expects(:config).once.returns({'number' => ['from', '/^([^\s]+)\s.*/', '\1']})
    assert_equal '+2068675309', mms.number
  end

  def test_mms_phone_number_with_errors
    mail = stub_mail(:from)
    mail.stubs(:from).returns(nil)
    mms = MMS2R::Media.new(mail)
    assert_nothing_raised do
      assert_equal '', mms.number
    end
  end

  def test_transform_text
    mail = stub_mail()
    mail.stubs(:from).returns(nil)
    mms = MMS2R::Media.new(mail)

    type = 'test/type'
    text = 'hello'

    # no match in the config
    result = [type, text]
    assert_equal result, mms.transform_text(type, text)

    # testing the default config
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "Sent via BlackBerry from T-Mobile")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', "Sent from my Verizon Wireless BlackBerry")
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', 'Sent from my iPhone')
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', 'Sent from your iPhone.')
    assert_equal ['text/plain', ''], mms.transform_text('text/plain', " \n\nimage/jpeg")

    # has a bad regexp
    mms.expects(:config).once.returns({'transform' => {type => [['(hello)', 'world']]}})
    assert_equal result, mms.transform_text(type, text)
    
    # matches in config
    mms.expects(:config).once.returns({'transform' => {type => [['/(hello)/', 'world']]}})
    assert_equal [type, 'world'], mms.transform_text(type, text)

    mms.expects(:config).once.returns({'transform' => {type => [['/^Ignore this part, (.+)/', '\1']]}})
    assert_equal [type, text], mms.transform_text(type, "Ignore this part, " + text)

    # chaining transforms
    mms.expects(:config).once.returns({'transform' => {type => [['/(hello)/', 'world'], 
                                                                ['/(world)/', 'mars']]}})
    assert_equal [type, 'mars'], mms.transform_text(type, text)

    # has a Iconv problem
    Iconv.expects(:new).raises
    mms.expects(:config).once.returns({'transform' => {type => [['(hello)', 'world']]}})
    assert_equal result, mms.transform_text(type, text)
  end

  def test_transform_text_to_utf8
    mail = TMail::Mail.load(mail_fixture('iconv-fr-text-01.mail'))
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['text/html'].size
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)
    text = IO.readlines("#{file}").join
    #assert_match(/D'ici un mois Géorgie/, text)
    assert_match(/D'ici un mois G\303\203\302\251orgie/, text)
    assert_equal("sample email message Fwd: sub D'ici un mois G\303\203\302\251orgie", 
                 mms.subject)
    mms.purge
  end

  def test_subject
    s = 'hello world'
    mail = stub_mail()
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    assert_equal s, mms.subject

    # second time through shouldn't process the subject again
    mail.expects(:subject).never
    assert_equal s, mms.subject
  end

  def test_subject_with_bad_mail_subject
    mail = stub_mail()
    mail.stubs(:subject).returns(nil)
    mms = MMS2R::Media.new(mail)
    assert_equal '', mms.subject
  end

  def test_subject_with_subject_ignored
    s = 'hello world'
    mail = stub_mail()
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    mms.stubs(:config).returns({'ignore' => {'text/plain' => [s]}})
    assert_equal '', mms.subject
  end

  def test_subject_with_subject_transformed
    s = 'Default Subject: hello world'
    mail = stub_mail()
    mail.stubs(:subject).returns(s)
    mms = MMS2R::Media.new(mail)
    mms.stubs(:config).returns(
      { 'ignore' => {},
        'transform' => {'text/plain' => [['/Default Subject: (.+)/', '\1']]}})
    assert_equal 'hello world', mms.subject
  end

  def test_attachment_should_return_nil_if_files_for_type_are_not_found
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:media).returns({})
    assert_nil mms.send(:attachment, ['text'])
  end

  def test_attachment_should_return_nil_if_empty_files_are_found
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:media).returns({'text/plain' => [Tempfile.new('test')]})
    assert_nil mms.send(:attachment, ['text'])
  end

  def test_type_from_filename(filename)
    mms = MMS2R::Media.new(stub_mail())
    assert_equal 'image/jpeg', mms.send(:type_from_filename, "example.jpg")
  end

  def test_type_from_filename_should_be_nil(filename)
    mms = MMS2R::Media.new(stub_mail())
    assert_nil mms.send(:type_from_filename, "example.example")
  end

  def test_attachment_should_return_duck_typed_file
    mms = MMS2R::Media.new(stub_mail())
    temp_big = temp_text_file("hello world")
    size = File.size(temp_text_file("hello world"))
    temp_small = temp_text_file("hello")
    mms.stubs(:media).returns({'text/plain' => [temp_small, temp_big]})
    duck_file = mms.send(:attachment, ['text'])
    assert_not_nil duck_file
    assert_equal true, File::exist?(duck_file)
    assert_equal true, File::exist?(temp_big)
    assert_equal temp_big, duck_file.local_path
    assert_equal File.basename(temp_big), duck_file.original_filename
    assert_equal size, duck_file.size
    assert_equal 'text/plain', duck_file.content_type
  end

  def test_empty_body
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:default_text).returns(nil)
    assert_equal "", mms.body
  end

  def test_body
    mms = MMS2R::Media.new(stub_mail())
    temp_big = temp_text_file("hello world")
    mms.stubs(:default_text).returns(File.new(temp_big))
    assert_equal "hello world", mms.body
  end

  def test_default_text
    mms = MMS2R::Media.new(stub_mail())
    temp_big = temp_text_file("hello world")
    temp_small = temp_text_file("hello")
    mms.stubs(:media).returns({'text/plain' => [temp_small, temp_big]})

    assert_equal temp_big, mms.default_text.local_path

    # second time through shouldn't setup the @default_text by calling attachment
    mms.expects(:attachment).never
    assert_equal temp_big, mms.default_text.local_path
  end

  def test_default_media
    mms = MMS2R::Media.new(stub_mail())
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
    mms = MMS2R::Media.new(stub_mail())
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

  def test_default_media_treats_gif_and_jpg_equally
    #it doesn't matter that these are text files, we just need say they are images
    temp_big = temp_text_file("hello world")
    temp_small = temp_text_file("hello")

    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:media).returns({'image/jpeg' => [temp_big], 'image/gif' => [temp_small]})
    assert_equal temp_big, mms.default_media.local_path

    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:media).returns({'image/gif' => [temp_big], 'image/jpg' => [temp_small]})
    assert_equal temp_big, mms.default_media.local_path
  end

  def test_purge
    mms = MMS2R::Media.new(stub_mail())
    mms.purge
    assert_equal false, File.exist?(mms.media_dir)
  end

  def test_ignore_media_by_filename_equality
    name = 'foo.txt'
    type = 'text/plain'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:config).returns({'ignore' => {type => [name]}})

    # type is not in the ingore
    part = stub(:sub_header => name, :body => 'a')
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and filename are in the ingore
    part = stub(:sub_header => name)
    assert_equal true, mms.ignore_media?(type, part)
    # type but not file name are in the ignore
    part = stub(:sub_header => 'bar.txt', :body => 'a')
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_filename
    name = 'x' * 300 + '.txt'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'text/plain')
    assert_equal 'x' * 251 + '.txt', mms.filename?(part)
  end

  def test_long_filename
    name = 'foo.txt'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'text/plain')
    assert_equal 'foo.txt', mms.filename?(part)
  end

  def test_filename_when_file_extension_missing_part
    name = 'foo'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'text/plain', :part_type? => 'text/plain')
    assert_equal 'foo.txt', mms.filename?(part)

    name = 'foo.janky'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'text/plain', :part_type? => 'text/plain')
    assert_equal 'foo.janky.txt', mms.filename?(part)
  end

  def test_ignore_media_by_filename_regexp
    name = 'foo.txt'
    regexp = '/foo\.txt/i'
    type = 'text/plain'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:config).returns({'ignore' => {type => [regexp, 'nil.txt']}})

    # type is not in the ingore
    part = stub(:sub_header => name, :body => 'a')
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and regexp for the filename are in the ingore
    part = stub(:sub_header => name)
    assert_equal true, mms.ignore_media?(type, part)
    # type but not regexp for filename are in the ignore
    part = stub(:sub_header => 'bar.txt', :body => 'a')
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_ignore_media_by_regexp_on_file_content
    name = 'foo.txt'
    content = "aaaaaaahello worldbbbbbbbbb"
    regexp = '/.*Hello World.*/i'
    type = 'text/plain'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:config).returns({'ignore' => {type => ['nil.txt', regexp]}})

    part = stub(:sub_header => name, :body => content)

    # type is not in the ingore
    assert_equal false, mms.ignore_media?('text/test', part)
    # type and regexp for the content are in the ingore
    assert_equal true, mms.ignore_media?(type, part)
    # type but not regexp for content are in the ignore
    part = stub(:sub_header => name, :body => 'no teapots')
    assert_equal false, mms.ignore_media?(type, part)
  end

  def test_ignore_media_when_file_content_is_empty
    mms = MMS2R::Media.new(stub_mail())

    # there is no conf but the part's body is empty
    part = stub(:sub_header => 'foo.txt', :body => "")
    assert_equal true, mms.ignore_media?('text/test', part)

    # there is no conf but the part's body is white space
    part = stub(:sub_header => 'foo.txt', :body => "\t\n\t\n            ")
    assert_equal true, mms.ignore_media?('text/test', part)
  end

  def test_add_file
    MMS2R.register('null.example.com', MMS2R::Media::NullCarrier)
    mail = stub_mail()
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
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name)
    assert_equal name, File.basename(mms.temp_file(part))
  end

  def test_process_media_for_text
    name = 'foo.txt'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:transform_text_part).returns(['text/plain', nil])
    part = stub(:sub_header => name, :content_type => 'text/plain', :part_type? => 'text/plain', :main_type => 'text')

    assert_equal ['text/plain', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['text/plain', 'hello world'])
    result = mms.process_media(part)
    assert_equal 'text/plain', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_with_empty_text
    name = 'foo.txt'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:transform_text_part).returns(['text/plain', nil])
    part = stub(:sub_header => name, :content_type => 'text/plain', :part_type? => 'text/plain', :main_type => 'text')

    assert_equal ['text/plain', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['text/plain', ''])
    assert_equal ['text/plain', nil], mms.process_media(part)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_application_smil
    name = 'foo.txt'
    mms = MMS2R::Media.new(stub_mail())
    mms.stubs(:transform_text_part).returns(['application/smil', nil])
    part = stub(:sub_header => name, :content_type => 'application/smil', :part_type? => 'application/smil', :main_type => 'application')

    assert_equal ['application/smil', nil], mms.process_media(part)

    mms.stubs(:transform_text_part).returns(['application/smil', 'hello world'])
    result = mms.process_media(part)
    assert_equal 'application/smil', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_application_octet_stream_when_image
    name = 'fake.jpg'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'application/octet-stream', :part_type? => 'application/octet-stream', :body => "data", :main_type => 'application')
    result = mms.process_media(part)
    assert_equal 'image/jpeg', result.first
    assert_match(/fake\.jpg$/, result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process_media_for_all_other_media
    name = 'foo.txt'
    mms = MMS2R::Media.new(stub_mail())
    part = stub(:sub_header => name, :content_type => 'faux/text', :part_type? => 'faux/text', :body => nil)
    part.expects(:main_type).with('text').returns('faux')

    assert_equal ['faux/text', nil], mms.process_media(part)

    part = stub(:sub_header => name, :content_type => 'faux/text', :part_type? => 'faux/text', :body => 'hello world')
    part.expects(:main_type).with('text').returns('faux')
    result = mms.process_media(part)
    assert_equal 'faux/text', result.first
    assert_equal 'hello world', IO.read(result.last)
    mms.purge # have to call purge since a file is put to disk as side effect
  end

  def test_process
    mms = MMS2R::Media.new(stub_mail())
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 'message.txt', File.basename(mms.media['text/plain'].first)
    assert_equal true, File.exist?(mms.media['text/plain'].first)
    assert_equal 1, File.size(mms.media['text/plain'].first)
    mms.purge
  end

  def test_process_with_multipart_double_parts
    mail = TMail::Mail.parse(load_mail('apple-double-image-01.mail').join)
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

  def test_process_with_multipart_alternative_parts
    mail = stub_mail()
    plain = stub(:sub_header => 'message.txt', :content_type => 'text/plain', :part_type? => 'text/plain', :body => 'a', :main_type => 'text')
    html = stub(:sub_header => 'message.html', :content_type => 'text/html', :part_type? => 'text/html', :body => 'a', :main_type => 'text')
    multi = stub(:content_type => 'multipart/alternative', :part_type? => 'multipart/alternative', :parts => [plain, html])
    mail.stubs(:multipart?).returns(true)
    mail.stubs(:parts).returns([multi])

    # the multipart/alternative should get flattend to text and html
    mms = MMS2R::Media.new(mail)
    assert_equal 2, mms.media.size
    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_not_nil mms.media['text/html']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['text/html'].size
    assert_equal 'message.txt', File.basename(mms.media['text/plain'].first)
    assert_equal 'message.html', File.basename(mms.media['text/html'].first)
    assert_equal true, File.exist?(mms.media['text/plain'].first)
    assert_equal true, File.exist?(mms.media['text/html'].first)
    assert_equal 1, File.size(mms.media['text/plain'].first)
    assert_equal 1, File.size(mms.media['text/html'].first)
    mms.purge
  end

  def test_process_when_media_is_ignored
    mail = stub_mail()
    plain = stub(:sub_header => 'message.txt', :content_type => 'text/plain', :part_type? => 'text/plain', :body => '')
    html = stub(:sub_header => 'message.html', :content_type => 'text/html', :part_type? => 'text/html', :body => '')
    multi = stub(:content_type => 'multipart/alternative', :part_type? => 'multipart/alternative', :parts => [plain, html])
    mail.stubs(:multipart?).returns(true)
    mail.stubs(:parts).returns([multi])
    mms = MMS2R::Media.new(mail, :process => :lazy)
    mms.stubs(:config).returns({'ignore' => {'text/plain' => ['message.txt'],
                                             'text/html' => ['message.html']}})
    assert_nothing_raised { mms.process }
    # the multipart/alternative should get flattend to text and html and then
    # what's flattened is ignored
    assert_equal 0, mms.media.size
    mms.purge
  end

  def test_process_when_yielding_to_a_block
    mail = stub_mail()

    plain = stub(:sub_header => 'message.txt', :content_type => 'text/plain', :part_type? => 'text/plain', :body => 'a', :main_type => 'text')
    html = stub(:sub_header => 'message.html', :content_type => 'text/html', :part_type? => 'text/html', :body => 'b', :main_type => 'text')
    mail.stubs(:multipart?).returns(true)
    mail.stubs(:parts).returns([plain, html])

    # the multipart/alternative should get flattend to text and html
    mms = MMS2R::Media.new(mail)
    assert_equal 2, mms.media.size
    mms.process do |type, files|
      assert_equal 1, files.size
      assert_equal true, type == 'text/plain' || type == 'text/html'
      assert_equal true, File.basename(files.first) == 'message.txt' || 
                         File.basename(files.first) == 'message.html'
      assert_equal true, File::exist?(files.first)
    end
    mms.purge
  end

  def test_domain_from_return_path
    mail = mock()
    mail.expects(:header).at_least_once.returns({'return-path' => '<joe@null.example.com>'})
    mail.expects(:from).at_least_once.returns([])
    domain = MMS2R::Media.domain(mail)
    assert_equal 'null.example.com', domain
  end

  def test_domain_from_from
    mail = mock()
    mail.expects(:header).at_least_once.returns({})
    mail.expects(:from).at_least_once.returns(['joe@null.example.com'])
    domain = MMS2R::Media.domain(mail)
    assert_equal 'null.example.com', domain
  end

  def test_domain_from_from_yaml
    f = File.join(MMS2R::Media.conf_dir, 'from.yml')
    YAML.expects(:load_file).once.with(f).returns(['example.com'])
    mail = mock()
    mail.expects(:header).at_least_once.returns({'return-path' => '<joe@null.example.com>'})
    mail.expects(:from).at_least_once.returns(['joe@example.com'])
    domain = MMS2R::Media.domain(mail)
    assert_equal 'example.com', domain
  end

  def test_unknown_device_type
    mail = TMail::Mail.load(mail_fixture('generic.mail'))
    mms = MMS2R::Media.new(mail)
    assert_equal :unknown, mms.device_type?
    assert_equal false, mms.is_mobile?
  end

  def test_iphone_device_type
    mail = TMail::Mail.load(mail_fixture('att-iphone-01.mail'))
    mms = MMS2R::Media.new(mail)
    assert_equal :iphone, mms.device_type?
    assert_equal true, mms.is_mobile?
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
      mail = TMail::Mail.load(mail_fixture(berry))
      mms = MMS2R::Media.new(mail)
      assert_equal :blackberry, mms.device_type?, "fixture #{berry} was not a blackberrry"
      assert_equal true, mms.is_mobile?
    end
  end

  def test_handset_device_type
    mail = TMail::Mail.load(mail_fixture('att-image-01.mail'))
    mms = MMS2R::Media.new(mail)
    assert_equal :handset, mms.device_type?
    assert_equal true, mms.is_mobile?
  end

end
