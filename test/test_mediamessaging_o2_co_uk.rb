require "test_helper"

class TestMediamessagingO2CoUk < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject
    mail = mail('mediamessaging_o2_co_uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mediamessaging.o2.co.uk", mms.carrier
    assert_equal "Office pic", mms.subject
    mms.purge
  end

  def test_image
    mail = mail('mediamessaging_o2_co_uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mediamessaging.o2.co.uk", mms.carrier

    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert mms.media['image/jpeg'].detect{|f| File.size(f) == 337}

    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = mail('mediamessaging_o2_co_uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mediamessaging.o2.co.uk", mms.carrier

    file = mms.default_media
    assert_equal 337, file.size

    mms.purge
  end

  def test_default_text_should_return_user_generated_content
    mail = mail('mediamessaging_o2_co_uk-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mediamessaging.o2.co.uk", mms.carrier

    file = mms.default_text
    assert_equal 10, file.size
    assert_equal "Office pic", file.read

    mms.purge
  end

end
