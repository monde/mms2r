require 'autotest'

class Autotest::Mms2r < Autotest

  def initialize # :nodoc:
    super
    @exceptions = /\.(git|svn)/
    @test_mappings = {
      %r%^conf/aliases.yml$% => proc { |_, m|
        ["test/test_mms2r_media.rb"]
      },
      %r%^conf/(.*)\.yml% => proc { |_, m|
        ["test/test_#{m[1].gsub(/\./,'_')}.rb"]
      },
      %r%^lib/mms2r.rb$% => proc { |_, m|
        ["test/test_mms2r_media.rb"]
      },
      %r%^lib/mms2r/media.rb$% => proc { |_, m|
        ["test/test_mms2r_media.rb"]
      },
      %r%^lib/mms2r/media/sprint.rb$% => proc { |_, m|
        ["test/test_pm_sprint_com.rb"]
      },
      %r%^test/test_.*\.rb$% => proc { |filename, _|
        filename
      }
    }
  end

  def path_to_classname(s)
    sep = File::SEPARATOR
    f = s.sub(/^test#{sep}/, '').sub(/\.rb$/, '').split(sep)
    f = f.map { |path| path.split(/_/).map { |seg| seg.capitalize }.join }
    f = f.map { |path| path =~ /^Test/ ? path : "Test#{path}"  }
    f.join
  end

end
