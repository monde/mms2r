require "test_helper"

class TestMmsMtnCoZa < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image_and_text_and_number
    mail = mail('mtn-southafrica-mms.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "mms.mtn.co.za", mms.carrier

    assert_equal "22222222222", mms.number

    assert_equal 1, mms.media.size
    assert_nil mms.media['image/bmp']
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Obsession Obsession", open(mms.media['text/plain'].first).read

    mms.purge
  end
end
