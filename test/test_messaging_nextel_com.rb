require "test_helper"

class TestMessagingNextelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_simple_text_is_nil
    mail = mail('nextel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    assert_nil mms.default_text

    mms.purge
  end

  def test_simple_default_media
    mail = mail('nextel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    file = mms.default_media
    assert_file_size file, 337
    assert_equal 'Jan15_0001.jpg', file.original_filename
    assert_equal 337, file.size
    assert_match(/Jan15_0001.jpg$/, file.local_path)

    mms.purge
  end

  def test_simple_image1
    mail = mail('nextel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Jan15_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image2
    mail = mail('nextel-image-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Mar12_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image3
    mail = mail('nextel-image-03.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Apr01_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_simple_image4
    mail = mail('nextel-image-04.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.nextel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/Mar20_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end
end
