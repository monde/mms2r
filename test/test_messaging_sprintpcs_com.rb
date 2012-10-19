require "test_helper"

class TestMessagingSprintpcsCom < Test::Unit::TestCase
  include MMS2R::TestHelper

  def test_simple_text
    mail = mail('sprint-pcs-text-01.mail')
    mms = MMS2R::Media.new(mail)
    assert_equal "2068675309", mms.number
    assert_equal "messaging.sprintpcs.com", mms.carrier

    assert_equal 1, mms.media.size
    assert_not_nil mms.media['text/plain']
    file = mms.media['text/plain'][0]
    assert_not_nil file
    assert File::exist?(file), "file #{file} does not exist"
    text = IO.read("#{file}")
    assert_match(/hello world/, text)
    mms.purge
  end

end
