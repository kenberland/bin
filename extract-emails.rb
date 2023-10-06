#!/usr/bin/env ruby

list = []
r = Regexp.new(/<([\w]+)@amazon[\.\w]+>/)
ARGF.each do |line|
  while new_email = line.match(r)
    list.push(new_email[1])
    line.sub!(r,'')
  end
end
puts list.sort


