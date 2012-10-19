require "test_helper"

class TestOrangemmsNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_orangemms_subject
    # orangemms.net service
    mail = mail('orange-uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "orangemms.net", mms.carrier
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orangemms_image
    # orangemms.net service
    mail = mail('orange-uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "orangemms.net", mms.carrier

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/picture.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337

    mms.purge
  end

  def test_orange_france_subject
    # orange.fr service
    mail = mail('orangefrance-text-and-image.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "0688675309", mms.number
    assert_equal "orange.fr", mms.carrier
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orange_france_processed_content
    # orange.fr service
    mail = mail('orangefrance-text-and-image.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "0688675309", mms.number
    assert_equal "orange.fr", mms.carrier

    # there should be one text and one image
    assert_equal 2, mms.media.size

    #text
    # there is a text banner that Orange attaches but
    # that should be ignored
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    file = mms.media['text/plain'].first
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.read("#{file}")
    assert_match(/Test ma poule/, text)

    # image
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/IMAGE.jpeg$/, mms.media['image/jpeg'].first)
    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end

  def test_orange_poland_subject
    # mmsemail.orange.pl service
    mail = mail('orangepoland-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "48508675309", mms.number
    assert_equal "mmsemail.orange.pl", mms.carrier
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orange_poland_non_empty_subject
    # mmsemail.orange.pl service
    mail = mail('orangepoland-text-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "48508675309", mms.number
    assert_equal "mmsemail.orange.pl", mms.carrier
    assert mms.subject, "whazzup"
    mms.purge
  end

  def test_orange_poland_content
    # mmsemail.orange.pl service
    mail = mail('orangepoland-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "48508675309", mms.number
    assert_equal "mmsemail.orange.pl", mms.carrier
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.read("#{file}")
    assert_match(/pozdro600/, text)
    mms.purge
  end

end
