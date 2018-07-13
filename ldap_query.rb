#!/usr/bin/env ruby
require 'open3'

query = ARGV[0]
match_string = "(&(|(uid=#{query})(sn=#{query}*)(givenname=#{query}*))(objectclass=amznPerson))"

cmd =<<EOD
ldapsearch -x -t -LLL -z 25 -h ldap.amazon.com -b o=amazon.com '#{match_string}' mail 2>/dev/null
EOD
buffer = nil
Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
  buffer = stdout.read
end

full_name = nil
email = nil

puts "Results:"

buffer.each_line do |line|
  # dn: cn=Ken Berland (berlandk),ou=people,ou=us,o=amazon.com
  # mail: loberlan@amazon.fr

  if line =~/^dn:/
    full_name = line.match(/cn=(.+)\s\(\w+\),/)[1]
    email = nil
  elsif line =~ /^mail:/
    email = line.match(/mail:\s(.+)$/)[1]
  else
    puts "#{full_name} <#{email}>" if full_name and email
  end
end
