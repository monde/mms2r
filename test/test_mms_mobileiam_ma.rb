require "test_helper"

class TestMmsMobileiamMa < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image_and_number
    mail = mail('maroctelecom-france-mms-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "98206867309", mms.number
    assert_equal "mms.mobileiam.ma", mms.carrier

    assert_equal 1, mms.media.size

    assert_equal 1, mms.media['image/gif'].size
    assert_match(/jalwapam\.gif$/, mms.media['image/gif'].first)
    assert_equal 1855, File.size(mms.media['image/gif'].first)

    mms.purge
  end
end
