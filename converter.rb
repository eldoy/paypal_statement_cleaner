#!/usr/bin/env ruby

require 'net/http'
require 'json'

def get_amount(amount, date, to = 'HKD', from = 'USD')
  date = date.to_s.split('/').map(&:to_f)
  date = Time.new(date[2], date[0], date[1])
  date = date.strftime("%Y-%m-%d")
  uri = URI("https://api.exchangeratesapi.io/#{date}?symbols=#{to}&base=#{from}")
  result = Net::HTTP.get(uri)
  result = JSON.parse(result)
  rate = result['rates'][to] rescue 0
  amount * rate
end

# TEST: puts get_amount(10.0, '3/31/2020')