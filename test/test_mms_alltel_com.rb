require "test_helper"

class TestMmsAlltelCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_subject_number_image
    mail = mail('alltel-mms-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "", mms.subject
    assert_equal "1234567890", mms.number
    assert_equal "mms.alltel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_equal 2, mms.media['image/jpeg'].size

    first = mms.media['image/jpeg'].detect{|f| /02-19-08_1709\.jpg/ =~ f}
    second = mms.media['image/jpeg'].detect{|f| /02-19-08_1710\.jpg/ =~ f}
    assert_equal 337, File.size(first)
    assert_equal 337, File.size(second)

    mms.purge
  end

  def test_alltel_image
    mail = mail('alltel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "message.alltel.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 2, mms.media['image/jpeg'].size
    assert_match(/eastern sky.jpg$/, mms.media['image/jpeg'][0])
    assert_match(/eastern sky.jpg$/, mms.media['image/jpeg'][1])
    assert_file_size mms.media['image/jpeg'][0], 337
    assert_file_size mms.media['image/jpeg'][1], 337

    mms.purge
  end

  def test_default_media_should_return_user_generated_content
    mail = mail('alltel-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "message.alltel.com", mms.carrier
    file = mms.default_media
    assert_equal 'eastern sky.jpg', file.original_filename
    mms.purge
  end

end
