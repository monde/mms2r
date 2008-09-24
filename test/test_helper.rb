require 'set'
require 'net/http'
require 'net/https'
require 'pp'

module MMS2R
  module TestHelper
  
    def assert_file_size(file, size)
      assert_not_nil(file, "file was nil")
      assert(File::exist?(file), "file #{file} does not exist")
      assert(File::size(file) == size, "file #{file} is #{File::size(file)} bytes, not #{size} bytes")
    end
  
    def load_mail(file)
      IO.readlines(mail_fixture(file))
    end

    def mail_fixture(file)
      "#{File.dirname(__FILE__)}/fixtures/#{file}"
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
