#!/usr/bin/env ruby

RATE = 7.75535

CURRENCY = 'HKD'

amount = ARGV[0].to_f

puts "#{amount * RATE} #{CURRENCY}"
