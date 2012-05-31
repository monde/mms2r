#--
# Copyright (c) 2012 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the LICENSE file for licensing information.
#++

class Mail::Message

    ##
    # Generically determines the mime-type of a message used in mms2r processing.
    # Guarantees a type is returned.

    def part_type?
      if self.content_type
        self.content_type.split(';').first.downcase
      else
        'text/plain'
      end
    end

    ##
    # override #filename to account for the true filename in the content_type
    # returns foo.jpg #content_type is 'image/jpeg; filename="foo.jpg"; name="foo.jpg"'
    # returns foo.jpg #content_type is 'image/jpeg;Name=foo.jpg'

    def filename
      if self.content_type && names = Hash[self.content_type.split(';').map{|t| t.strip.split('=')}]
        if name = names.detect{|key,val| key.downcase == 'filename'} || names.detect{|key,val| key.downcase == 'name'}
          return (name.last.match(/^"?(.+?)"?$/))[1]
        end
      end

      find_attachment
    end


end
