require "test_helper"

class TestMmsVodacom4meCoZa < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_image_only
    mail = mail('vodacom4me-co-za-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.vodacom4me.co.za", mms.carrier

    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/Ugly\.jpg$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_should_have_phone_number
    mail = mail('vodacom4me-co-za-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.vodacom4me.co.za", mms.carrier

    mms.purge
  end

  def test_image_and_text
    mail = mail('vodacom4me-co-za-02.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+2068675309", mms.number
    assert_equal "mms.vodacom4me.co.za", mms.carrier

    assert_not_nil mms.media['text/plain']
    assert_equal "Hello World", open(mms.media['text/plain'].first).read

    assert_nil mms.media['text/html']

    assert_not_nil mms.media['image/jpeg'].first
    assert_match(/DSC00184\.JPG$/, mms.media['image/jpeg'].first)
    mms.purge
  end

  def test_new_image_and_number
    mail = mail('vodacom4me-southafrica-mms-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+12345678901", mms.number
    assert_equal "mms.vodacom4me.co.za", mms.carrier

    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']

    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['image/gif'].size
    assert_not_nil mms.media['image/gif'].first
    assert_match(/127612345678901h5mmqcMPXEMPXE40mms.vodacom4me.co.za-slide-0-image.gif$/, mms.media['image/gif'].first)
    mms.purge
  end

  def test_new_lots_of_images
    mail = mail('vodacom4me-southafrica-mms-04.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "+12345678901", mms.number
    assert_equal "mms.vodacom4me.co.za", mms.carrier

    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']

    assert_not_nil mms.media['image/gif'].at(0)
    assert_match(/ZedLandingMedium\.gif$/, mms.media['image/gif'].at(0))

    assert_not_nil mms.media['image/jpeg'].at(0)
    assert_match(/240x320_thumb\.jpg\.\.jpeg$/, mms.media['image/jpeg'].at(0))

    assert_not_nil mms.media['image/jpeg'].at(1)
    assert_match(/240x320_thumb\.jpg\.jpeg$/, mms.media['image/jpeg'].at(1))

    assert_not_nil mms.media['image/jpeg'].at(2)
    assert_match(/wallpaper1940_thumb\.jpg\.jpeg$/, mms.media['image/jpeg'].at(2))

    assert_not_nil mms.media['image/jpeg'].at(3)
    assert_match(/playboy\.jpg\.jpeg$/, mms.media['image/jpeg'].at(3))

    assert_not_nil mms.media['image/gif'].at(1)
    assert_match(/h1_170_30\.gif$/, mms.media['image/gif'].at(1))

    assert_not_nil mms.media['image/jpeg'].at(4)
    assert_match(/banner0\.jpg\.jpeg$/, mms.media['image/jpeg'].at(4))

    assert_not_nil mms.media['image/gif'].at(2)
    assert_match(/adv_act_list\.gif$/, mms.media['image/gif'].at(2))

    assert_not_nil mms.media['image/gif'].at(3)
    assert_match(/adv_act_next\.gif$/, mms.media['image/gif'].at(3))

    assert_not_nil mms.media['image/gif'].at(4)
    assert_match(/adv_nav_back_cat_app_home\.gif$/, mms.media['image/gif'].at(4))

    assert_not_nil mms.media['image/gif'].at(5)
    assert_match(/adv_tab_mypage\.gif$/, mms.media['image/gif'].at(5))

    assert_not_nil mms.media['image/jpeg'].at(5)
    assert_match(/creaturecomforts8_240x320_thumb\.jpg\.jpeg/, mms.media['image/jpeg'].at(5))
    mms.purge
  end
end
