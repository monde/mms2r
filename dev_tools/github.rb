# based on Trouble shooting section in http://gems.github.com/
require 'rubygems'
require 'rubygems/specification'
data = File.read(File.join(File.dirname(__FILE__), "..", "mms2r.gemspec"))
spec = nil
result = Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
puts spec
(!!result) ? exit(0) : exit(1)
