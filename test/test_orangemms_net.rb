require File.join(File.dirname(__FILE__), "..", "lib", "mms2r")
require File.join(File.dirname(__FILE__), "test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
gem 'tmail', '>= 1.2.1'
require 'tmail'

class TestOrangemmsNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_orangemms_subject
    # orangemms.net service
    mail = TMail::Mail.parse(load_mail('orange-uk-image-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orangemms_image
    # orangemms.net service
    mail = TMail::Mail.parse(load_mail('orange-uk-image-01.mail').join)
    mms = MMS2R::Media.new(mail)

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
    mail = TMail::Mail.parse(load_mail('orangefrance-text-and-image.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orange_france_processed_content
    # orange.fr service
    mail = TMail::Mail.parse(load_mail('orangefrance-text-and-image.mail').join)
    mms = MMS2R::Media.new(mail)

    # there should be one text and one image
    assert_equal 2, mms.media.size

    #text
    # there is a text banner that Orange attaches but
    # that should be ignored
    assert_not_nil mms.media['text/plain'] 
    assert_equal 1, mms.media['text/plain'].size
    file = mms.media['text/plain'].first
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
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
    mail = TMail::Mail.parse(load_mail('orangepoland-text-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_equal "", mms.subject
    mms.purge
  end

  def test_orange_poland_non_empty_subject
    # mmsemail.orange.pl service
    mail = TMail::Mail.parse(load_mail('orangepoland-text-02.mail').join)
    mms = MMS2R::Media.new(mail)
    assert mms.subject, "whazzup"
    mms.purge
  end

  def test_orange_poland_content
    # mmsemail.orange.pl service
    mail = TMail::Mail.parse(load_mail('orangepoland-text-01.mail').join)
    mms = MMS2R::Media.new(mail)
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.readlines("#{file}").join
    assert_match(/pozdro600/, text)
    mms.purge
  end
  
end
