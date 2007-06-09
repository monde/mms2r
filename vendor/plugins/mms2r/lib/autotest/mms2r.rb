require 'autotest'

class Autotest::Mms2r < Autotest

  def initialize # :nodoc:
    super
    @exceptions = /\.svn|test\/files|test\/test_helper|doc\/|lib\/vendor|coverage\//
    @test_mappings = {
      %r%^conf/(mms2r_.*media)_(subject|transform|ignore)\.yml% => proc { |_, m|
        ["test/test_#{m[1]}.rb"]
      },
      %r%^lib/mms2r/(.+)\.rb$% => proc { |_, m|
        ["test/test_mms2r_#{m[1]}.rb"]
      },
      %r%^lib/mms2r.rb$% => proc { |_, m|
        ["test/test_mms2r_media.rb"]
      },
      %r%^test/test_mms2r_.*media\.rb$% => proc { |filename, _|
        filename
      }
    }
  end

  def path_to_classname(s)
    f = s.sub(/.*test_mms2r_(.+).rb$/, '\1')
    f = f.map { |path| path.split(/_/).map { |seg| seg.capitalize }.join }
    f.unshift("MMS2R")
    l = f.pop
    f.push( l =~ /Test$/ ? l : "#{l}Test" )
    f.join('::')
  end

end
