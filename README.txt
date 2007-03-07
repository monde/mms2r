mms2r

by Mike Mondragon

http://mms2r.rubyforge.org/    

== DESCRIPTION:
  
MMS2R is a library that decodes the parts of an MMS message to disk while 
stripping out advertising injected by the cellphone carriers.  MMS messages are 
multipart email and the carriers often inject branding into these messages. 

If MMS2R is not aware of a particular carrier no extra processing is done 
to the MMS other than decoding and consolodating its media.

Contact the author to add additional carriers to be processed by the library.

== FEATURES/PROBLEMS:

Corpus of carriers currently processed by MMS2R:

* AT&T/Cingular => mmode.com
* Cingular => mms.mycingular.com
* Sprint => pm.sprint.com
* Sprint => messaging.sprintpcs.com
* T-Mobile => tmomail.net
* Verizon => vzwpix.com
  
== SYNOPSIS:

  require 'rubygems'
  require 'mms2r'
  require 'tmail'
  media = TMail::Media.parse(IO.readlines("mymail.file").join)
  mms = MMS2R::Media.create(mail,Logger.new(STDOUT))
TODO fix the example
  mms.process
  mms.media['image/jpeg'].each {|f| puts "${f}"}
  mms.media['text/plain'].each {|f| puts "${f}"}

== REQUIREMENTS:

* TMail
* Mechanize
* Hpricot

== INSTALL:

* sudo gem install mms2r

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
