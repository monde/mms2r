require "test_helper"

class TestMmsUsccNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_mms_uscc_net
    # mms.uscc.net service
    mail = mail('us-cellular-image-01.mail')
    mms = MMS2R::Media.new(mail)

    assert_equal "5418675309", mms.number
    assert_equal "mms.uscc.net", mms.carrier
    assert_equal "", mms.subject
    assert_equal 2, mms.media.size
    assert_nil mms.media['text/html']
    assert_nil mms.media['image/gif']

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_match(/0315001513.jpg$/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)

    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert_equal true, File::exist?(file)
    text = IO.read("#{file}")
    assert_match(/This is what i do at work most the day/, text)

    mms.purge
  end

end
