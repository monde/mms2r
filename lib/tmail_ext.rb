
class TMail::MessageIdHeader #:nodoc:
  def real_body
    @body
  end
end

class TMail::Mail

    ##
    # Determines the mime-type of a part.  Guarantees a type is returned.

    def part_type?
      self.content_type('text/plain')
    end

end
