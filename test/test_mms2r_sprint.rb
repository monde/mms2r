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
    f = "files/dot.jpg"
    res.body = File.open("#{File.dirname(__FILE__)}/#{f}", 'rb') { |file|
       file.read
    }
  end
end

class BrokenImageServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    res.code = 404
    res.body = '<html><head><title>404 Not Found</title></head><body><h1>Not Found</h1></body></html>'
  end
end

class SimpleVideoServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "video/quicktime"
    f = "files/sprint.mov"
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
    SERVLETS[path].new({}).send("do_#{request.method}", request, res)
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

class MMS2RSprintTest < Test::Unit::TestCase
  include MMS2R::TestHelper

  def setup
    @log = Logger.new(STDOUT)
    @log.level = Logger::DEBUG
    @log.datetime_format = "%H:%M:%S"
  end

  def teardown; end

  def test_simple_video
    mail = TMail::Mail.parse(load_mail('sprint-video-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['video/quicktime'][0])
    assert_match(/000_0123a01234567895_1.mov$/, mms.media['video/quicktime'][0])

    assert_file_size(mms.media['video/quicktime'][0], 49063)
    mms.purge
  end

  def test_simple_image
    mail = TMail::Mail.parse(load_mail('sprint-image-01.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 1)   
    assert_nil(mms.media['text/plain'])
    assert_nil(mms.media['text/html'])
    assert_not_nil(mms.media['image/jpeg'][0])
    assert_match(/000_0123a01234567890_1.jpg$/, mms.media['image/jpeg'][0])

    assert_file_size(mms.media['image/jpeg'][0], 337)
    mms.purge
  end

  def test_broken_image
    mail = TMail::Mail.parse(load_mail('sprint-image-02.mail').join)
    mms = MMS2R::Media.create(mail)
    mms.process

    assert(mms.media.size == 0)

    mms.purge
  end

  def test_simple_text
    mail = TMail::Mail.parse(load_mail('sprint-text-01.mail').join)
    mms = MMS2R::Media.create(mail)
    assert_equal(MMS2R::SprintMedia, mms.class, "expected a #{MMS2R::SprintMedia} and received a #{mms.class}")
    mms.process
    assert_not_nil(mms.media['text/plain'])   
    file = mms.media['text/plain'][0]
    assert_not_nil(file)
    assert(File::exist?(file), "file #{file} does not exist")
    text = IO.readlines("#{file}").join
    assert_match(/hello world/, text)
    mms.purge
  end
end
