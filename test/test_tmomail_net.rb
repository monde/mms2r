require "test_helper"

class TestTmomailNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_ignore_simple_image
    mail = mail('tmobile-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "tmomail.net", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/12-01-06_1234.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_message_with_body_text
    mail = mail('tmobile-image-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "16128675309", mms.number
    assert_equal "tmomail.net", mms.carrier

    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/07-25-05_0935.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_equal "Lillies", text.strip

    mms.purge
  end

  def test_image_from_blackberry
    mail = mail('tmobile-blackberry.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "srs.bis.na.blackberry.com", mms.carrier

    assert_nil mms.media['text/plain']

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/\/IMG00239\.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_image_from_blackberry2
    mail = mail('tmobile-blackberry-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "example.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/\/IMG00141\.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_tmobile_uk_image_and_text_and_number
    mail = mail('mmsreply.t-mobile.co.uk-text-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal '12345678901', mms.number
    assert_equal 'mmsreply.t-mobile.co.uk', mms.carrier

    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size
    assert_equal 1, mms.media['text/plain'].size

    assert_equal "Do you know this office? Do you know this office? Do \nyou know this office? Do you know this office?", mms.default_text.read

    assert_file_size mms.media['image/jpeg'][0], 337
    file = mms.default_media
    assert_equal 'Image002.jpg', file.original_filename

    mms.purge
  end

  def test_tmo_blackberry_net
    mail = mail('tmo.blackberry.net-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal '2068675309', mms.number
    assert_equal 'IMG00440.jpg', mms.subject
    assert_equal 'tmo.blackberry.net', mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    assert_file_size mms.media['image/jpeg'][0], 337
    file = mms.default_media
    assert_equal 'IMG00440.jpg', file.original_filename

    mms.purge
  end
end
