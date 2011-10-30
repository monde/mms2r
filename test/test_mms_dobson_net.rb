require "test_helper"

class TestMmsDobsonNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_mms_dobson_net
    # mms.dobson.net service
    mail = mail('dobson-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mms.dobson.net", mms.carrier

    assert_equal 2, mms.media.size

    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/04-18-07_1723.jpg$/, mms.media['image/jpeg'][0])
    assert_file_size(mms.media['image/jpeg'][0], 337)

    assert_equal nil, mms.media['application/smil'] # dobson phones have weird SMIL that can be ignored.
    assert_not_nil(mms.media['text/plain'])
    assert_equal 1, mms.media['text/plain'].size
    assert_equal "Body", IO.read(mms.media['text/plain'][0])

    mms.purge
  end

  def test_body_should_return_user_text
    mail = mail('dobson-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mms.dobson.net", mms.carrier

    assert_equal 'Body', mms.body

    mms.purge
  end
end
