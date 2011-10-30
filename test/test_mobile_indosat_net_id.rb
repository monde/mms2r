require "test_helper"

class TestMobileIndosatNetId < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_mms_indosat_with_yahoo_service
    # mobile.indosat.net.id service
    mail = mail('indosat-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mobile.indosat.net.id", mms.carrier
    assert_equal "", mms.subject
    assert_nil mms.media['text/html']
    assert_equal 2, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Foto_14_.jpg/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    assert_equal "Hello World", mms.default_text.read
    mms.purge
  end

  def test_mms_indosat_phone_number_with_yahoo_service
    # mobile.indosat.net.id service
    mail = mail('indosat-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mobile.indosat.net.id", mms.carrier
    mms.purge
  end

  def test_mms_indosat
    # mobile.indosat.net.id service
    mail = mail('indosat-image-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mobile.indosat.net.id", mms.carrier
    assert_equal "Please pick up while I prepair another.", mms.subject
    assert_nil mms.media['text/html']
    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/6033_small.jpeg/, mms.media['image/jpeg'].first)
    assert_file_size(mms.media['image/jpeg'].first, 337)
    mms.purge
  end
end
