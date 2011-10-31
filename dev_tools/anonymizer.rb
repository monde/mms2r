#! /usr/bin/env ruby

if ARGV.size != 3
  puts "Usage: anonymizer.rb message_file phone_number email_address"
  exit(1)
end

message_file = ARGV[0]
phone_number = ARGV[1]
email_address = ARGV[2]

message = File.read(message_file)
message.gsub!(phone_number, '2068675309')
message.gsub!(email_address, 'tommy.tutone@example.com')

out = File.open(message_file, "wb")
out.puts message
out.close
