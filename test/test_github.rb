# based on Trouble shooting section in http://gems.github.com/
require 'test/unit'
require 'rubygems'

class TestGithub < Test::Unit::TestCase

  def test_build_github_gem
    result = `ruby #{File.join(File.dirname(__FILE__), "..", "dev_tools", "github.rb")}`
    assert_equal 0, $?.exitstatus
  end

end
