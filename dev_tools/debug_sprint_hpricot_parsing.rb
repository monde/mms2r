require 'rubygems'
require 'hpricot'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'pp'

if ARGV[0].nil?
  puts "please execute with a file path to a Sprint HTML file that was extracted from a MMS"
  puts "ruby #{$0} MYFILE"
  exit
end

doc = open(ARGV[0]) { |f| Hpricot(f) }

puts "TITLE: #{doc.at('title').inner_html}"

#phone number is tucked away in the comment in the head
c = doc.search("/html/head/comment//").last
t = c.content.gsub(/\s+/m," ").strip
number = / name=&quot;MDN&quot;&gt;(\d+)&lt;/.match(t)[1]
puts "NUMBER: #{number}"

#if there is a text message with the MMS its in the
#inner html of the only pre on the page
text = doc.search("/html/body//pre").first.inner_html
puts "TEXT: #{text}"

# just see what they say this MMS is it really doesn't
# mean anything, the content is in paux image with 
# a RECIPIENT in its URI path
trs = doc.search("/html/body//tr")
text = trs[3].search("/td/p/font/b/")
case text.text
when /You have a Video Mail from/
  puts "it claims to be a video"
when /You have a Picture Mail from /
  puts "it claims to be an image"
else
  puts "what is it? #{text.text}"
end

# group all the images together
srcs = Array.new
imgs = doc.search("/html/body//img")
imgs.each do |i|
  src = i.attributes['src']
  #next unless /pictures.sprintpcs.com\/+mmps\/RECIPIENT\//.match(src)
  #we don't want to double fetch content and we only
  #want to fetch media from the content server, you get
  #a clue about that as there is a RECIPIENT in the URI path
  next unless /mmps\/RECIPIENT\//.match(src)
  next if srcs.detect{|s| s.eql?(src)}
  srcs << src
end

# now fetch the media
puts "there are #{srcs.size} sources to fetch"
cnt = 0
srcs.each do |src|
  puts "--"
  puts "FETCHING:\n  #{src}"

   url = URI.parse(src)
   #res = Net::HTTP.get_response(url)
   agent = "Mozilla/5.0 (X11; U; Minix3 i686 (x86_64); en-US; rv:1.8.1.1) Gecko/20061208 Firefox/2.0.0.1"
   res = Net::HTTP.start(url.host, url.port) { |http|
     req = Net::HTTP::Get.new(url.request_uri, {'User-Agent' => agent})
     http.request(req)
   }

  # prep and write a file
  base = /\/RECIPIENT\/([^\/]+)\//.match(src)[1]
  ext = /^[^\/]+\/(.+)/.match(res.content_type)[1]
  file_name ="#{base}.#{cnt}.#{ext}"
  puts "writing file: #{file_name}"
  File.open(file_name,'w'){ |f| f.write(res.body) }
  puts "file is sized #{File.size(file_name)}"
  cnt = cnt + 1
end

puts "no images or video" if srcs.size == 0
