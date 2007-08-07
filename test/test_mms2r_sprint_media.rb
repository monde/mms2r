$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require File.dirname(__FILE__) + "/test_helper"
require 'test/unit'
require 'webrick'
require 'net/http'
require 'rubygems'
require 'mms2r'
require 'mms2r/media'
require 'tmail/mail'
require 'logger'

# this style of test was inspired by WWW::Mechanize

class SimpleImageServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "image/jpeg"
    f = "fixtures/dot.jpg"
    res.body = File.open("#{File.dirname(__FILE__)}/#{f}", 'rb') { |file|
       file.read
    }
  end
end

class BrokenImageServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    raise
    #res['Content-Type'] = "text/html"
    #res.code = 404
    #res.body = '<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1></body></html>'
  end
end

class SimpleVideoServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "video/quicktime"
    f = "fixtures/sprint.mov"
    res.body = File.open("#{File.dirname(__FILE__)}/#{f}", 'rb') { |file|
       file.read
    }
  end
end

class Net::HTTP

  alias :old_do_start :do_start

  def do_start
    @started = true
  end

  SERVLETS = {
    '/mmps' => SimpleImageServlet,
    '/simpleimage' => SimpleImageServlet,
    '/brokenimage' => BrokenImageServlet,
    '/simplevideo' => SimpleVideoServlet
  }

  alias :old_request :request

  def request(request, *data, &block)
    url = URI.parse(request.path)
    path = url.path.gsub('%20', ' ').match(/^\/[^\/]+/)[0]
    res = Response.new
    request.query = WEBrick::HTTPUtils.parse_query(url.query)
    servlet = case
              when request.query['HACK'].eql?('VIDEO')
                SimpleVideoServlet
              when request.query['HACK'].eql?('IMAGE')
                SimpleImageServlet
              when request.query['HACK'].eql?('BROKEN')
                BrokenImageServlet
              else
                  SERVLETS[path]
              end
    servlet.new({}).send("do_#{request.method}", request, res)
    res.code ||= "200"
    res
  end
end

class Net::HTTPRequest
  attr_accessor :query, :body, :cookies
end

class Response
  include Net::HTTPHeader

  attr_reader :code
  attr_accessor :body, :query, :cookies

  def code=(c)
    @code = c.to_s
  end

  alias :status :code
  alias :status= :code=

  def initialize
    @header = {}
    @body = ''
    @code = nil
    @query = nil
    @cookies = []
  end

  def read_body
    yield body
  end

  def value()
    return body if "200".eql?(@code)
    raise Net::HTTPError.new('400 Bad Request', 'Good Bye')
  end
end

class MMS2R::SprintMediaTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teardown; end

  def test_mms_should_have_text
    mail = TMail::Mail.parse(load_mail('sprint-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal 1, mms.media.size
    assert_equal 1, mms.media['text/plain'].size
    assert_equal 7, mms.get_text.size
    text = IO.readlines("#{mms.get_text.path}").join
    assert_match(/Tea Pot/, text)
    mms.purge
  end

  def test_mms_should_have_a_phone_number
    mail = TMail::Mail.parse(load_mail('sprint-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal '2068509247', mms.get_number
    mms.purge
  end

  def test_should_have_simple_video
    mail = TMail::Mail.parse(load_mail('sprint-video-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['video/quicktime'][0]
    assert_match(/000_0123a01234567895_1-0.mov$/, mms.media['video/quicktime'][0])

    assert_file_size mms.media['video/quicktime'][0], 49063
    
    assert_equal nil, mms.get_subject, "Default Sprint subject not scrubbed."
    
    mms.purge
  end

  def test_should_have_simple_image
    mail = TMail::Mail.parse(load_mail('sprint-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_not_nil mms.media['image/jpeg'][0]
    assert_match(/000_0123a01234567890_1-0.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size mms.media['image/jpeg'][0], 337
    
    assert_equal nil, mms.get_subject, "Default Sprint subject not scrubbed"
    
    mms.purge
  end

  def test_should_have_two_images
    mail = TMail::Mail.parse(load_mail('sprint-two-images-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 1, mms.media.size
    assert_nil mms.media['text/plain']
    assert_nil mms.media['text/html']
    assert_equal 2, mms.media['image/jpeg'].size
    assert_not_nil mms.media['image/jpeg'][0]
    assert_not_nil mms.media['image/jpeg'][1]
    assert_match(/000_0123a01234567890_1-0.jpg$/, mms.media['image/jpeg'][0])
    assert_match(/000_0123a01234567890_1-1.jpg$/, mms.media['image/jpeg'][1])

    assert_file_size mms.media['image/jpeg'][0], 337
    assert_file_size mms.media['image/jpeg'][1], 337
    
    assert_equal nil, mms.get_subject, "Default Sprint subject not scrubbed"
    
    mms.purge
  end

  def test_image_should_be_missing
    mail = TMail::Mail.parse(load_mail('sprint-broken-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert_equal 0, mms.media.size

    mms.purge
  end

  def test_get_body_should_return_nil_when_there_is_no_user_text
    mail = TMail::Mail.parse(load_mail('sprint-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process
    assert_equal nil, mms.get_body
  end
end
