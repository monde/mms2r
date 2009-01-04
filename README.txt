= mms2r

  by Mike Mondragon
  http://mms2r.rubyforge.org/ 
  http://rubyforge.org/tracker/?group_id=3065 
  http://github.com/monde/mms2r/tree/master
  http://peepcode.com/products/mms2r-pdf

== DESCRIPTION
  
MMS2R is a library that decodes the parts of an MMS message to disk while 
stripping out advertising injected by the mobile carriers.  MMS messages are 
multipart email and the carriers often inject branding into these messages.  Use
MMS2R if you want to get at the real user generated content from a MMS without
having to deal with the cruft from the carriers.

If MMS2R is not aware of a particular carrier no extra processing is done to the 
MMS other than decoding and consolidating its media.

Contact the author to add additional carriers to be processed by the library.  
Suggestions and patches appreciated and welcomed!

Corpus of carriers currently processed by MMS2R:

* 1nbox/Idea: 1nbox.net
* 3 Ireland: mms.3ireland.ie
* Alltel: mms.alltel.com
* AT&T/Cingular/Legacy: mms.att.net, txt.att.net, mmode.com, mms.mycingular.com, 
  cingularme.com, mobile.mycingular.com pics.cingularme.com
* Bell Canada: txt.bell.ca
* Bell South / Suncom: bellsouth.net
* Cricket Wireless: mms.mycricket.com
* Dobson/Cellular One: mms.dobson.net
* Helio: mms.myhelio.com
* Hutchison 3G UK Ltd: mms.three.co.uk
* INDOSAT M2: mobile.indosat.net.id
* LUXGSM S.A.: mms.luxgsm.lu
* Maroc Telecom / mms.mobileiam.ma
* MTM South Africa: mms.mtn.co.za
* NetCom (Norway): mms.netcom.no
* Nextel: messaging.nextel.com
* O2 Germany: mms.o2online.de
* O2 UK: mediamessaging.o2.co.uk
* Orange & Regional Oranges: orangemms.net, mmsemail.orange.pl, orange.fr
* PLSPICTURES.COM mms hosting: waw.plspictures.com
* PXT New Zealand: pxt.vodafone.net.nz
* Rogers of Canada: rci.rogers.com
* SaskTel: sms.sasktel.com
* Sprint: pm.sprint.com, messaging.sprintpcs.com, sprintpcs.com
* T-Mobile: tmomail.net, mmsreply.t-mobile.co.uk, tmo.blackberry.net
* TELUS Corporation (Canada): mms.telusmobility.com, msg.telus.com
* UAE MMS: mms.ae
* Unicel: unicel.com, info2go.com 
  (note: mobile number is tucked away in a text/plain part for unicel.com)
* Verizon: vzwpix.com, vtext.com
* Virgin Mobile: vmpix.com
* Virgin Mobile of Canada: vmobile.ca
* Vodacom: mms.vodacom4me.co.za

== FEATURES

* #default_media and #default_text methods return a File that can be used in 
  attachment_fu 
* #process supports blocks to for enumerating over the content of the MMS
* #process can be made lazy when :process => :lazy is passed to new
* logging is enabled when :logger => your_logger is passed to new

== BOOKS

MMS2R, Making email useful
http://peepcode.com/products/mms2r-pdf

== SYNOPSIS

  require 'rubygems'
  require 'mms2r'

  # required for the example
  require 'tmail'
  require 'fileutils'

  mail = TMail::Mail.parse(IO.readlines("sample-MMS.file").join)
  mms = MMS2R::Media.new(mail)

  puts "MMS has default carrier subject" if mms.subject.empty?

  # access the sender's phone number
  puts "MMS was from phone #{mms.number}"

  # most MMS are either image or video, default_media will return the largest
  # (non-advertising) video or image found
  file = mms.default_media
  puts "MMS had a media: #{file.inspect}" unless file.nil?

  # finds the largest (non-advertising) text found
  file = mms.default_text
  puts "MMS had some text: #{file.inspect}" unless file.nil?

  # mms.media is a hash that is indexed by mime-type.
  # The mime-type key returns an array of filepaths
  # to media that were extract from the MMS and
  # are of that type
  mms.media['image/jpeg'].each {|f| puts "#{f}"}
  mms.media['text/plain'].each {|f| puts "#{f}"}

  # print the text (assumes MMS had text)
  text = IO.readlines(mms.media['text/plain'].first).join
  puts text

  # save the image (assumes MMS had a jpeg)
  FileUtils.cp mms.media['image/jpeg'].first, '/some/where/useful', :verbose => true

  puts "does the MMS have quicktime video? #{!mms.media['video/quicktime'].nil?}"

  # Block support, process and receive all media types of video.
  mms.process do |media_type, files|
    # assumes a Clip model that is an AttachmentFu
    Clip.create(:uploaded_data => files.first, :title => "From phone") if media_type =~ /video/
  end

  # Another AttachmentFu example, Picture model is an AttachmentFu
  picture = Picture.new
  picture.title = mms.subject
  picture.uploaded_data = mms.default_media
  picture.save!

  #remove all the media that was put to temporary disk
  mms.purge

== REQUIREMENTS

* Hpricot
* TMail

== INSTALL

conventional
* sudo gem install mms2r

github
* sudo gem sources -a http://gems.github.com
* sudo gem install monde-mms2r

== SOURCE

git clone git://github.com/monde/mms2r.git
svn co svn://rubyforge.org/var/svn/mms2r/trunk mms2r

== CONTRIBUTE

If you contribute a patch that is accepted then you'll get developer rights 
for the project on RubyForge.  Please ensure your work includes 100% test 
converage.  The library is ZenTest autotest discovery enabled so running 
autotest in the root of the project is very helpful during development.

== AUTHORS

Copyright (c) 2007-2008 by Mike Mondragon (blog[http://blog.mondragon.cc/])

MMS2R's Flickr page[http://www.flickr.com/photos/8627919@N05/]

== CONTRIBUTORS

* Luke Francl (blog[http://railspikes.com/])
* Will Jessup (blog[http://www.willjessup.com/])
* Shane Vitarana (blog[http://www.shanesbrain.net/])
* Layton Wedgeworth (http://www.beenup2.com/)
* Jason Haruska (blog[http://software.haruska.com/])
* Dave Myron (company[http://contentfree.com/])
* Vijay Yellapragada
* Jesse Dp
* David Alm
* Jeremy Wilkins
* Matt Conway
* Kai Kai
* Michael DelGaudio

== LICENSE

(The MIT License)

Copyright (c) 2007, 2008 Mike Mondragon (mikemondragon@gmail.com).
All rights reserved.

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
