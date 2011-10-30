require "test_helper"

class TestUnicelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject_number_image_unicel
    mail = mail('unicel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "joeexample", mms.number
    assert_equal "unicel.com", mms.carrier

    assert_equal "", mms.subject

    assert_equal 2, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /moto_0002\.jpg/ =~ f}
    assert_equal 337, File.size(image)

    file = mms.media['text/plain'][0]
    text = IO.readlines("#{file}").join
    assert_match(/2068675309/, text)

    mms.purge
  end

  def test_subject_number_image_info2go
    mail = mail('info2go-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
    assert_equal "2068675309", mms.number
    assert_equal "info2go.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/jpeg'].size

    image = mms.media['image/jpeg'].detect{|f| /Image047\.jpeg/ =~ f}
    assert_equal 337, File.size(image)

    mms.purge
  end

end
