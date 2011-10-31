require "test_helper"

class Test1nboxNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image_and_text_and_number_and_carrier
    mail = mail('1nbox-2images-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "+919812345678", mms.number
    assert_equal "1nbox.net", mms.carrier
    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "testing123456789012", open(mms.media['text/plain'].first).read

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['text/plain'].size
    assert_match(/@003\.jpg$/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_no_plain_text
    mail = mail('1nbox-2images-02.mail')
    mms = MMS2R::Media.new(mail)

    assert_nil mms.media['text/plain']

    assert_equal "+919898765432", mms.number
    assert_equal "1nbox.net", mms.carrier
    assert_equal 1, mms.media.size

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/showpicture\.jpeg$/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_extra_chars
    mail = mail('1nbox-2images-03.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/\/Copy of test1\.jpg$/, mms.media['image/jpeg'].first)

    mms.purge
  end

  def test_image_with_plain_email
    mail = mail('1nbox-2images-04.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Hi,I'M TESTERS/MALE/23/IND/GOV.SRVC.01234567890.", open(mms.media['text/plain'].first).read

    assert_equal "1234567890", mms.number
    assert_equal "1nbox.net", mms.carrier

    assert_not_nil mms.media['image/gif']
    assert_equal 1, mms.media['image/gif'].size
    assert_match(/@003\.gif$/, mms.media['image/gif'].first)

    mms.purge
  end
end
