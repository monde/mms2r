module MMS2R
  module TestHelper
  
    def assert_file_size(file, size)
      assert_not_nil(file, "file was nil")
      assert(File::exist?(file), "file #{file} does not exist")
      assert(File::size(file) == size, "file #{file} is #{File::size(file)} bytes, not #{size} bytes")
    end
  
    def load_mail(file)
      IO.readlines("#{File.dirname(__FILE__)}/fixtures/#{file}")
    end
  end
end
