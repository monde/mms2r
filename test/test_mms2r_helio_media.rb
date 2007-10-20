$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'


class MMS2R::HelioMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    mail = TMail::Mail.parse(load_mail('helio-image-01.mail').join)
    @mms = MMS2R::Media.create(mail)
    @mms.process
  end

  def test_instantiated_class_should_be_helio_media
    assert_equal @mms.class, MMS2R::HelioMedia
  end

  def test_get_number_should_return_correct_number
    number = @mms.number()
    assert_equal number, 7608070850.to_s
  end

  def test_subject_should_return_correct_subject
    title = @mms.subject()
    assert_equal title, "Test image"
  end

  def test_body_should_return_correct_body
    body = @mms.body()
    assert_equal body, "Test image"
  end

  def test_get_attachment_should_return_jpeg
    image = @mms.get_media()
    assert_not_nil @mms.media['image/jpeg'][0]
    assert_match(/0628070005.jpg$/, @mms.media['image/jpeg'][0])
  end

  def teardown
    @mms.purge
  end

end
