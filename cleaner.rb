#!/usr/bin/env ruby

require 'csv'
require './converter.rb'

class Cleaner

  attr_reader :rows, :entries, :bank, :csv, :headers

  # The default currency, delete all other currencies and use currency conversion
  DC = 'USD'

  # The outgoing currency
  OC = 'HKD'

  # The file to write the result to
  OUT = 'result.csv'

  def initialize
    files = Dir['*.csv']
    files -= [OUT]

    if files.empty?
      puts "No CSV files found"
      exit(1)
    else
      puts "Found #{files.first}, processsing ..."
    end

    @rows = CSV.parse(File.read('./download.csv'), :encoding => "bom|utf-8", :headers => :first_row)

    # Convert to array and clean keys and values
    @csv = []
    @rows.each{|row| @csv << clean(row.to_hash)}

    # Read Headers
    @headers = @csv.first.keys

    @entries = []
    @bank = []

    @csv.each_with_index do |row, index|
      # Save bank first
      next_row = @csv[index + 1]
      # Save the bank row
      @bank << next_row if next_row and row["Type"] == "General Withdrawal"

      # Skip if another currency, currency conversions take care of that
      next unless row["Currency"] == DC

      # Remove non-default currency rows
      @entries << row if !["Account Hold"].include?(row["Type"])
    end
    puts
    puts "Done.\n\n"
  end

  def gross(denomination = nil)
    sum(@entries, "Gross", denomination)
  end

  def fees(denomination = nil)
    sum(@entries, "Fee", denomination)
  end

  def net(denomination = nil)
    sum(@entries, "Net", denomination)
  end

  def bank_sum
    sum(@bank, "Net")
  end

  def cost
    (gross('-').to_f - bank_sum.to_f).round(2) * -1
  end

  # Write to file except bank withdrawals
  def write_result
    CSV.open(OUT, "w") do |r|
      r << @headers
      @entries.each do |row|
        r << row.values
      end
    end
  end

  # Print the result to screen
  def print_result
    # puts "File: #{@csv.size}"
    sep = "  "
    puts "=== RESULT (#{@entries.size} entries) ===\n\n"
    puts "___ GROSS ___\nGAIN #{gross} #{OC} #{sep} IN #{gross('+')} #{OC} #{sep} OUT #{gross('-')} #{OC}\n\n"
    puts "___ FEES ___\nGAIN #{fees} #{OC} #{sep} IN #{fees('+')} #{OC} #{sep} OUT #{fees('-')} #{OC}\n\n"
    puts "___ NET ___\nGAIN #{net} #{OC} #{sep} IN #{net('+')} #{OC} #{sep} OUT #{net('-')} #{OC}\n\n"
    puts "=== BANK (#{@bank.size}) ===\n#{bank_sum} #{OC}\n\n"
    puts "~~~ COST ~~~\n#{cost}\n\n"
    puts "Done."
  end

  private

  # Sum amount of entries, pass '-' or '+' to only get negative or positive sums.
  def sum(rows, type, denomination = nil)
    denomination = nil unless ['-', '+', nil].include?(denomination)
    r = 0.0
    rows.each do |row|
      amount = row[type].to_f

      # Convert amount on that day
      amount = get_amount(amount, row["Date"])

      sleep 0.1

      r += amount if !denomination or (denomination == '+' and amount > 0) or (denomination == '-' and amount < 0)
    end
    sprintf("%0.02f", r.round(2))
  end

  # Strip, remove weird chars
  def clean(hash)
    tmp = {}
    hash.each do |k, v|
      next if !(v and k)
      v = v.strip
      v = "0" if v == '...'

      k = k.strip
      v = v.gsub(",", "") if %w[Gross Fee Net Balance].include?(k)

      tmp[k] = v if k and v
    end
    tmp
  end
end


c = Cleaner.new
c.print_result
c.write_result
