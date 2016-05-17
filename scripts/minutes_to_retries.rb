#!/usr/bin/env ruby -w

seconds_to_reach = 10 * 60
default_interval = 2
retry_max_interval = 128

current_interval = 2
total_interval = 0
exceptions_count = 1

loop do
  break if total_interval > seconds_to_reach  
  exceptions_count += 1
  
  current_interval = current_interval*2 > retry_max_interval ? retry_max_interval : current_interval*2

  total_interval += current_interval
end

puts exceptions_count
