require "test_helper"

class TestPmSprintCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def mock_sprint_image(message_id)
    response = mock('response')
    body = mock('body')
    connection = mock('connection')
    response.expects(:content_type).twice.returns('image/jpeg')
    response.expects(:body).returns(body)
    response.expects(:code).never
    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).once.returns connection
    connection.expects(:get2).with(
      # 1.9.2
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90&ext=.jpg&iconifyVideo=true&wm=1'
      # 1.8.7
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&outquality=90&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU'
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).once.returns(response)
  end

  def mock_sprint_purged_image(message_id)
    response = mock('response')
    body = mock('body')
    connection = mock('connection')
    response.expects(:content_type).once.returns('text/html')
    response.expects(:body).returns(body)
    response.expects(:code).once.returns('500')
    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).once.returns connection
    connection.expects(:get2).with(
      # 1.9.2
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90&ext=.jpg&iconifyVideo=true&wm=1'
      # 1.8.7
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&outquality=90&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU'
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).once.returns(response)
  end

  def mock_sprint_ajax
    response = mock('response')
    body = mock('body')
    # this is a response from a real sprint message
    file = File.open("./test/fixtures/sprint-ajax-response-success.json", "rb")
    json = file.read
    body.expects(:to_str).returns json
    connection = mock('connection')
    connection.stubs(:use_ssl=).returns(true)
    response.expects(:body).twice.returns(body)
    response.expects(:code).once.returns('200')
    response.expects(:content_type).twice.returns('text/html')

    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).twice.returns connection
    connection.expects(:get2).with(
      # 1.9.2
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90&ext=.jpg&iconifyVideo=true&wm=1'
      # 1.8.7
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&outquality=90&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU'
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).twice.returns(response)
  end

  def mock_sprint_ajax_purged
    response = mock('response')
    body = mock('body')
    # this is a response from a real sprint message
    file = File.open("./test/fixtures/sprint-ajax-response-failure.html", "rb")
    error_html = file.read
    body.expects(:to_str).returns error_html
    connection = mock('connection')
    connection.stubs(:use_ssl=).returns(true)
    response.expects(:body).twice.returns(body)
    response.expects(:code).once.returns('500')
    response.expects(:content_type).once.returns('text/html')

    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).twice.returns connection
    connection.expects(:get2).with(
      # 1.9.2
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?inviteToken=PE5rJ5PdYzzwk7V7zoXU&outquality=90&ext=.jpg&iconifyVideo=true&wm=1'
      # 1.8.7
      # '//mmps/RECIPIENT/001_2066c7013e7ca833_1/2?wm=1&ext=.jpg&outquality=90&iconifyVideo=true&inviteToken=PE5rJ5PdYzzwk7V7zoXU'
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).twice.returns(response)
  end

  def test_mms_should_have_text
    mail = mail('sprint-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068765309", mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    file = mms.media['text/plain'].first
    assert_equal true, File.exist?(file)
    assert_match(/\.txt$/, File.basename(file))
    assert_equal "Tea Pot", IO.read(file)
    mms.purge
  end

  def test_mms_should_have_a_phone_number
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    mms.purge
  end

  def test_should_have_simple_video
    mail = mail('sprint-video-01.mail')

    response = mock('response')
    body = mock('body')
    connection = mock('connection')
    response.expects(:content_type).twice.returns('video/quicktime')
    response.expects(:body).returns(body)
    response.expects(:code).never
    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).once.returns connection
    connection.expects(:get2).with(
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).once.returns(response)

    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['video/quicktime']
    assert_equal 1, mms.media['video/quicktime'].size
    assert_equal "000_259e41e851be9b1d_1-0.mov", File.basename(mms.media['video/quicktime'][0])

    mms.purge
  end

  def test_should_have_simple_image
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/001_2066c7013e7ca833_1-0.jpg$/, mms.media['image/jpeg'][0])

    mms.purge
  end

  def test_collect_image_using_block
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal 1, mms.media.size
    file_array = nil
    mms.process do |k, v|
      file_array = v if (k == 'image/jpeg')
      assert_equal 1, file_array.size
      file = file_array.first
      assert_not_nil file = file_array.first
      assert_equal "001_2066c7013e7ca833_1-0.jpg", File.basename(file)
    end
    mms.purge
  end

  def test_process_internals_should_only_be_executed_once
    mail = mail('sprint-image-01.mail')
    mock_sprint_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal 1, mms.media.size

    # second time through shouldn't go into the was_processed block
    mms.mail.expects(:parts).never

    mms.process{|k, v| }

    mms.purge
  end

  def test_should_have_two_images
    mail = mail('sprint-two-images-01.mail')

    response = mock('response')
    body = mock('body')
    connection = mock('connection')
    response.expects(:content_type).times(4).returns('image/jpeg')
    response.expects(:body).twice.returns(body)
    response.expects(:code).never
    Net::HTTP.expects(:new).with('pictures.sprintpcs.com', 80).twice.returns connection
    connection.expects(:get2).with(
      kind_of(String),
      { "User-Agent" => MMS2R::Media::USER_AGENT }
    ).twice.returns(response)

    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_equal 2, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'][0]
    assert_not_nil mms.media['image/jpeg'][1]
    assert_match(/001_104058d23d79fb6a_1-0.jpg$/, mms.media['image/jpeg'][0])
    assert_match(/001_104058d23d79fb6a_1-1.jpg$/, mms.media['image/jpeg'][1])

    mms.purge
  end

  def test_image_should_be_missing
    # this test is questionable
    mail = mail('sprint-broken-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_message_is_missing_in_mail
    # this test is questionable
    mail = mail('sprint-image-missing-message.mail')
    mock_sprint_ajax
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media['text/plain'].size
    
    # test that the message was extracted from the ajax response
    message = IO.read(mms.media['text/plain'].first)
    assert_equal "First text content.", message
    
    # test that the &nbsp; was removed ()
    assert message.last.bytes.to_a != [194, 160]
    
    mms.purge
  end

  def test_message_is_missing_in_mail_purged_from_content_server
    # this test is questionable
    mail = mail('sprint-image-missing-message.mail')
    mock_sprint_ajax_purged
    mms = MMS2R::Media.new(mail)

    assert_equal '5135455555', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_image_should_be_purged_from_content_server
    mail = mail('sprint-image-01.mail')
    mock_sprint_purged_image(mail.message_id)
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier

    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_body_should_return_empty_when_there_is_no_user_text
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal "", mms.body
  end

  def test_sprint_write_file
    mail = mock(:message_id => 'a')
    mail.expects(:from).at_least_once.returns(['joe@pm.sprint.com'])
    mail.expects(:return_path).at_least_once.returns('joe@pm.sprint.com')
    mms = MMS2R::Media.new(mail, :process => :lazy)
    type = 'text/plain'
    content = 'foo'
    file = Tempfile.new('sprint')
    file.close

    type, file = mms.send(:sprint_write_file, type, content, file.path)
    assert_equal 'text/plain', type
    assert_equal content, IO.read(file)
  end

  def test_subject
    mail = mail('sprint-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal "", mms.subject
  end

  def test_new_subject
    mail = mail('sprint-new-image-01.mail')
    mock_sprint_ajax
    mms = MMS2R::Media.new(mail)
    assert_equal '2068675309', mms.number
    assert_equal "pm.sprint.com", mms.carrier
    assert_equal "", mms.subject
  end

end
