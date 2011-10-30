require "test_helper"

class TestMmsO2onlineDe < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject
    mail = mail('o2-de-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "o2.5551234", mms.number
    assert_equal "mms.o2online.de", mms.carrier
    assert_equal "this is a subject", mms.subject
    mms.purge
  end

  def test_image
    mail = mail('o2-de-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "o2.5551234", mms.number
    assert_equal "mms.o2online.de", mms.carrier

    # o2 is ungly, you cant' tel the logo is different than user content by its file name
    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 2, mms.media['image/jpeg'].size
    assert mms.media['image/jpeg'].detect{|f| File.size(f) == 337}

    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = mail('o2-de-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "o2.5551234", mms.number
    assert_equal "mms.o2online.de", mms.carrier
    file = mms.default_media
    assert_equal 1275, file.size

    mms.purge
  end

  def test_default_text_should_return_user_generated_content
    mail = mail('o2-de-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "o2.5551234", mms.number
    assert_equal "mms.o2online.de", mms.carrier
    file = mms.default_text
    #assert_equal 42, file.size
    assert_equal "This is text before the image. Thank you!", file.read.strip

    mms.purge
  end

end
