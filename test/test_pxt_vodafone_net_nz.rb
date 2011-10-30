require "test_helper"

class TestPxtVodafoneNetNz < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    mail = mail('pxt-image-01.mail')
    @mms = MMS2R::Media.new(mail)
    assert_equal '+55512345', @mms.number
    assert_equal 'pxt.vodafone.net.nz', @mms.carrier
  end

  def teardown
    @mms.purge
  end

  def test_pxt_text_returns_text_plain
    assert_not_nil(@mms.media['text/plain'])

    file = @mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/Kia ora ano Luke/, text)

    assert_match(/Kia ora ano Luke/, @mms.body)
  end

  def test_subject_should_clear_default_pxt_message
    assert_equal "", @mms.subject
  end

end
