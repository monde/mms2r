# -*- ruby -*-

require 'rubygems'
require 'hoe'

begin
  require 'rcov/rcovtask'
rescue LoadError
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'mms2r'

Hoe.new('mms2r', MMS2R::Media::VERSION) do |p|
  p.rubyforge_name = 'mms2r'
  p.author = 'Mike Mondragon'
  p.email = 'mikemondragon@gmail.com'
  p.summary = 'Extract user media from MMS (and not carrier cruft)'
  p.description = p.paragraphs_of('README.txt', 2..6).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 1).first.strip
  p.changes = p.paragraphs_of('History.txt', 0..3).join("\n\n")
  p.extra_deps << ['hpricot', '>= 0.6.0']
  p.extra_deps << ['tmail', '>= 1.2.1']
  p.clean_globs << 'coverage'
end

begin
  Rcov::RcovTask.new do |t|
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
    t.rcov_opts << "--exclude rcov.rb,hpricot.rb,hpricot/.*\.rb"
  end
rescue NameError
end

# vim: syntax=Ruby
