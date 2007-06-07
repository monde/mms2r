= mms2r

  http://mms2r.rubyforge.org/    

== DESCRIPTION:
  
MMS2R is a library that decodes the parts of an MMS message to disk while 
stripping out advertising injected by the cellphone carriers.  MMS messages are 
multipart email and the carriers often inject branding into these messages.  Use
MMS2R if you want to get at the real user generated content from a MMS without
having to deal with the cruft from the carriers.

If MMS2R is not aware of a particular carrier no extra processing is done 
to the MMS other than decoding and consolidating its media.

Contact the author to add additional carriers to be processed by the 
library.  Suggestions and patches appreciated and welcomed!

Corpus of carriers currently processed by MMS2R:

* AT&T/Cingular => mmode.com
* Cingular => mms.mycingular.com
* Cingular => cingularme.com
* Dobson/Cellular One => mms.dobson.net
* Nextel => messaging.nextel.com
* Sprint => pm.sprint.com
* Sprint => messaging.sprintpcs.com
* T-Mobile => tmomail.net
* Verizon => vzwpix.com
* Verizon => vtext.com

== FEATURES

* get_media and get_text methods return a File that can be used in attachment_fu 

== SYNOPSIS:

  require 'rubygems'
  require 'mms2r'
  require 'mms2r/media'
  require 'tmail'
  require 'fileutils'

  # TMail::Mail.parse is what ActionMailer::Base.receive(email) does, see:
  # http://wiki.rubyonrails.com/rails/pages/HowToReceiveEmailsWithActionMailer
  email = TMail::Mail.parse(IO.readlines("sample-MMS.file").join)
  mms = MMS2R::Media.create(email,Logger.new(STDOUT))

  # process finds all the media in a MMS, strips advertsing, then
  # writes the user generated media to disk in a temporary subdirectory
  mms.process

  puts "MMS has default carrier subject!" if mms.get_subject.eql?("")

  # access the senders phone number
  puts "MMS was from phone #{mms.get_number}"

  # most MMS are either image or video, get_media will return the largest
  # (non-advertising) video or image found
  file = mms.get_media
  puts "MMS had a media: #{file.inspect}" unless file.nil?

  # get_text return the largest (non-advertising) text found
  file = mms.get_text
  puts "MMS had some text: #{file.inspect}" unless file.nil?

  # mms.media is a hash that is indexed by mime-type.
  # The mime-type key returns an array of filepaths
  # to media that were extract from the MMS and
  # are of that type
  mms.media['image/jpeg'].each {|f| puts "#{f}"}
  mms.media['text/plain'].each {|f| puts "#{f}"}

  # Block support, process and receive all media types of video
  mms.process do |media_type, file|
    results << file if media_type =~ /video/
  end
  # or
  image = mms.media['image/jpeg'].first

  # print the text (assumes MMS had text)
  text = IO.readlines(mms.media['text/plain'][0]).join
  puts text

  # save the image (assumes MMS had a jpeg)
  FileUtils.cp mms.media['image/jpeg'][0], '/some/where/use/ful', :verbose => true

  puts "does the MMS have video? #{!mms.media['video/quicktime'].nil?}"

  #remove all the media that was put to temporary disk
  mms.purge

== REQUIREMENTS:

* Hpricot

== INSTALL:

* sudo gem install mms2r

== CONTRIBUTE:

If you contribute a patch that we accept then generally we'll
give you developer rights for the project on RubyForge.  Please
ensure your work includes 100% test converage.  Your text 
coverage can be verified with the rcov and heckle rack tasks.

== Authors

Copyright (c) 2007 by Mike Mondragon (blog[http://blog.mondragon.cc/])

== Contributors

* Luke Francl (blog[http://railspikes.com/])
* Will Jessup (blog[http://www.willjessup.com/])
* Shane Vitarana (blog[http://www.shanesbrain.net/])

== LICENSE:

(The MIT License)

Copyright (c) 2007 Mike Mondragon.  All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
