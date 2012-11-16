module MMS2R
  class Version

    def self.major
      3
    end

    def self.minor
      9
    end

    def self.patch
      1
    end

    def self.pre
      nil
    end

    def self.to_s
      [major, minor, patch, pre].compact.join('.')
    end

  end
end
