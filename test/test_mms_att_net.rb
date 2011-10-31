require "test_helper"

class TestMmsAttNet < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_mms_att_net
    # mms.att.net service
    mail = mail('att-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "12068675309", mms.number
    assert_equal "mms.att.net", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Photo_12.jpg$/, mms.media['image/jpeg'][0])
    assert_file_size(mms.media['image/jpeg'][0], 337)
    mms.purge
  end

  def test_mms_att_net_subject
    # mms.att.net service

    mail = mail('att-image-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "12068675309", mms.number
    assert_equal "mms.att.net", mms.carrier

    assert_equal "", mms.subject
    mms.purge
  end

  def test_txt_att_net
    # txt.att.net service
    mail = mail('att-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "5551234", mms.number
    assert_equal "txt.att.net", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil(mms.media['text/plain'])
    assert_equal "Hello World", IO.read(mms.media['text/plain'][0])

    mms.purge
  end

  def test_cingularme_com
    # cingularme.com service
    mail = mail('cingularme-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "cingularme.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil(mms.media['text/plain'])
    assert_equal "hello world", IO.read(mms.media['text/plain'][0])

    mms.purge
  end

  def test_mmode_com
    # mmode.com service
    mail = mail('mmode-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "12068675309", mms.number
    assert_equal "mmode.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['image/jpeg']
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/picture\(3\).jpg$/, mms.media['image/jpeg'][0])
    assert_file_size(mms.media['image/jpeg'][0], 337)
    mms.purge
  end

  def test_mms_mycingular_com
    # mms.mycingular.com service
    mail = mail('mycingular-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mms.mycingular.com", mms.carrier

    assert_equal 2, mms.media.size
    assert_not_nil mms.media['text/plain']
    assert_not_nil mms.media['text/plain'][0]
    assert_equal 1, mms.media['text/plain'].size
    assert_not_nil mms.media['image/jpeg']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_equal 1, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/04-18-07_1723.jpg$/, mms.media['image/jpeg'][0])
    assert_file_size(mms.media['image/jpeg'][0], 337)
    assert_equal "Water", IO.read(mms.media['text/plain'][0])
    mms.purge
  end

  def test_image_from_blackberry
    mail = mail('att-blackberry.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "example.com", mms.carrier

    assert_not_nil mms.media['text/plain']
    assert_equal "Hello world", IO.readlines(mms.media['text/plain'].first).join.strip

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/\/BC-WAKE\.jpg$/, mms.media['image/jpeg'].first)
  end

  def test_image_from_blackberry2
    mail = mail('att-blackberry-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mms.att.net", mms.carrier

    assert_equal 2, mms.media.size

    assert_not_nil mms.media['text/plain']
    assert_match(/^Testing memorymail from my blackberry and at&t.$/, IO.readlines(mms.media['text/plain'].first).join.strip)

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/IMG00367.jpg/, mms.media['image/jpeg'].first)
  end

  def test_mobile_mycingular_com
    # mobile.mycingular.com service
    mail = mail('mobile.mycingular.com-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "mobile.mycingular.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil(mms.media['text/plain'])
    assert_equal "I hate people that send text messages about skateboarding.", IO.read(mms.media['text/plain'][0])

    mms.purge
  end

  def test_pics_cingularme_com
    # pics.cingularme.com service
    mail = mail('pics.cingularme.com-image-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "pics.cingularme.com", mms.carrier

    mms.purge
  end
end
