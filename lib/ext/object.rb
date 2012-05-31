class Object

  unless respond_to?(:blank?)

    def blank?
      respond_to?(:empty?) ? empty? : !self
    end

  end

  unless respond_to?(:present?)

    def present?
      !blank?
    end

  end

end
