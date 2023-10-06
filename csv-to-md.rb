#!/usr/bin/env ruby

require 'csv'
first_row = true
CSV.foreach("/dev/stdin") do |row|
  if first_row
    puts row.join('|')
    puts (['--'] * row.size).join('|')
    first_row = false
  else
    puts row.join('|')
  end
end
exit

# Headers are part of data
data = CSV.parse(<<~ROWS, headers: true)
  Name,Department,Salary
  Bob,Engineering,1000
  Jane,Sales,2000
  John,Management,5000
ROWS

data.class      #=> CSV::Table
data.first      #=> #<CSV::Row "Name":"Bob" "Department":"Engineering" "Salary":"1000">
data.first.to_h #=> {"Name"=>"Bob", "Department"=>"Engineering", "Salary"=>"1000"}
