# do it like rake http://ozmm.org/posts/do_it_like_rake.html
begin
  gem 'test-unit', '= 1.2.3'
  require 'test/unit'
rescue NoMethodError
  require 'rubygems'
  gem 'test-unit', '= 1.2.3'
  require 'test/unit'
end

%W{ set net/http net/https pp tempfile mocha }.each do |g|
  begin
    require g
  rescue LoadError
    require 'rubygems'
    require g
  end
end

# NOTE when we upgrade to test-unit 2.x.x or greater we'll not need redgreen,
# it's baked into test-unit
begin require 'redgreen'; rescue LoadError; end

require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib', 'mms2r')

module MMS2R
  module TestHelper

    def assert_file_size(file, size)
      assert_not_nil(file, "file was nil")
      assert(File::exist?(file), "file #{file} does not exist")
      assert(File::size(file) == size, "file #{file} is #{File::size(file)} bytes, not #{size} bytes")
    end

    def fixture(file)
      File.join(File.expand_path(File.dirname(__FILE__)), "fixtures", file)
    end

    def mail_fixture(file)
      fixture(file)
    end

    def mail(name)
      Mail.read(mail_fixture(name))
    end

    def smart_phone_mock(make_text = 'Apple', model_text = 'iPhone', jpeg = true)
      mail = stub('mail',
                  :from => ['joe@example.com'],
                  :return_path => '<joe@example.com>',
                  :message_id => 'abcd0123',
                  :multipart? => true,
                  :header => {})

      part = stub('part',
                  :part_type? => "image/#{jpeg ? 'jpeg' : 'tiff'}",
                  :body => Mail::Body.new('abc'),
                  :multipart? => false,
                  :filename => "foo.#{jpeg ? 'jpg' : 'tif'}" )

      mail.stubs(:parts).returns([part])
      exif = stub('exif', :make => make_text, :model => model_text)
      if jpeg
        EXIFR::JPEG.expects(:new).at_least_once.returns(exif)
      else
        EXIFR::TIFF.expects(:new).at_least_once.returns(exif)
      end
      mail
    end
  end
end

class Hash
  def except(*keys)
    rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject { |key,| rejected.include?(key) }
  end

  def except!(*keys)
    replace(except(*keys))
  end
end

# monkey patch Net::HTTP so un caged requests don't go over the wire
module Net #:nodoc:
  class HTTP #:nodoc:
    alias :old_net_http_request :request
    alias :old_net_http_connect :connect

    def request(req, body = nil, &block)
      prot = use_ssl ? "https" : "http"
      uri_cls = use_ssl ? URI::HTTPS : URI::HTTP
      query = req.path.split('?',2)
      opts = {:host => self.address,
             :port => self.port, :path => query[0]}
      opts[:query] = query[1] if query[1]
      uri = uri_cls.build(opts)
      raise ArgumentError.new("#{req.method} method to #{uri} not being handled in testing")
    end

    def connect
      raise ArgumentError.new("connect not being handled in testing")
    end

  end
end
