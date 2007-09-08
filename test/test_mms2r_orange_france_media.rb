$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

class MMS2R::OrangeFranceMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_create_should_return_orange_france
    mail = TMail::Mail.parse(load_mail('orangefrance-text-and-image.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal MMS2R::OrangeFranceMedia, mms.class, "expected a #{MMS2R::OrangeFranceMedia} and received a #{mms.class}"
  end

  def test_empty_subject
    mail = TMail::Mail.parse(load_mail('orangefrance-text-and-image.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_nil mms.get_subject
  end

  def test_processed_content
    mail = TMail::Mail.parse(load_mail('orangefrance-text-and-image.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

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
    assert_match /Test ma poule/, text

    # image
    assert_not_nil mms.media['image/jpeg'] 
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match /IMAGE.jpeg$/, mms.media['image/jpeg'].first
    assert_file_size mms.media['image/jpeg'].first, 337

    mms.purge
  end
  
end
