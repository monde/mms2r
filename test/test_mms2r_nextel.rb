$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2RNextelTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teardown; end

  def test_simple_get_text_is_nil
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_nil(mms.get_text)

    mms.purge
  end

  def test_simple_get_text
    mail = TMail::Mail.parse(load_mail('cingularme-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    file = mms.get_text
    assert_file_size(file, 13)
    assert_match(/\.txt$/, file.original_filename)
    assert_equal(13, file.size)
    assert_match(/\.txt$/, file.local_path)

    mms.purge
  end

  def test_simple_get_media_is_nil
    mail = TMail::Mail.parse(load_mail('cingularme-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_nil(mms.get_media)

    mms.purge
  end

  def test_simple_get_media
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    file = mms.get_media
    assert_file_size(file, 337)
    assert_equal('Jan15_0001.jpg', file.original_filename)
    assert_equal(337, file.size)
    assert_match(/Jan15_0001.jpg$/, file.local_path)

    mms.purge
  end

  def test_simple_image1
    mail = TMail::Mail.parse(load_mail('nextel-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/Jan15_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size(mms.media['image/jpeg'][0], 337)

    mms.purge
  end

  def test_simple_image2
    mail = TMail::Mail.parse(load_mail('nextel-image-02.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/Mar12_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size(mms.media['image/jpeg'][0], 337)

    mms.purge
  end

  def test_simple_image3
    mail = TMail::Mail.parse(load_mail('nextel-image-03.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/Apr01_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size(mms.media['image/jpeg'][0], 337)

    mms.purge
  end

  def test_simple_image4
    mail = TMail::Mail.parse(load_mail('nextel-image-04.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/Mar20_0001.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size(mms.media['image/jpeg'][0], 337)

    mms.purge
  end
end
