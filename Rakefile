# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'rcov/rcovtask'

$LOAD_PATH.unshift 'lib'
require 'mms2r'
require 'mms2r/media'

Hoe.new('mms2r', MMS2R::Media::VERSION) do |p|
  p.rubyforge_name = 'mms2r'
  p.author = 'Mike Mondragon'
  p.email = 'mike@mondragon.cc'
  p.summary = 'Extract media from MMS '
  p.description = p.paragraphs_of('README.txt', 2..8).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['hpricot']
  p.extra_deps << ['rcov']
  p.clean_globs << 'coverage'
end

Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
  t.rcov_opts << "--exclude rcov.rb,hpricot.rb,hpricot/.*\.rb"
end

# vim: syntax=Ruby
