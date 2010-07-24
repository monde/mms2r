# -*- ruby -*-

require 'rubygems'
require 'hoe'

begin
  require 'rcov/rcovtask'
rescue LoadError
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require 'mms2r'

Hoe.plugin :bundler
Hoe.spec('mms2r') do |p|
  p.version        = MMS2R::Media::VERSION
  p.rubyforge_name = 'mms2r'
  p.author         = ['Mike Mondragon']
  p.email          = ['mikemondragon@gmail.com']
  p.summary        = 'Extract user media from MMS (and not carrier cruft)'
  p.description    = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url            = p.paragraphs_of('README.txt', 1).first.strip
  p.changes        = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['nokogiri', '>= 1.4.0']
  p.extra_deps << ['mail', '>= 2.2.5']
  p.extra_deps << ['uuidtools', '>= 2.1.1']
  p.extra_deps << ['exifr', '>= 1.0.1']
  p.clean_globs << 'coverage'
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |rcov|
    rcov.pattern = 'test/**/test_*.rb'
    rcov.verbose = true
    rcov.rcov_opts << "--exclude rcov.rb"
  end
rescue
  task :rcov => :check_dependencies
end

RDoc::Task.new do |rdoc|
  rdoc.title    = "mms2r-#{MMS2R::Media::VERSION}"
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '-f' << 'horo'
  rdoc.options << '--main' << 'README.txt'
end

# vim: syntax=Ruby
