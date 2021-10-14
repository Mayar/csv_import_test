#!/usr/bin/env ruby
require 'awesome_print'
require 'benchmark'
require 'csv'

require_relative 'db'
require_relative 'parser'

DB_CONNECT = {dbname: 'mayar'}

time = Benchmark.realtime do
  db = DB.new(DB_CONNECT)
  3.times do |fno|
    fno += 1
    filo = "price_#{fno}.csv"
    unless File.file?(filo)
      puts "Incorrect filename: #{filo}"
      next
    end
    puts "#{Time.now.strftime('%Y.%m.%d %H:%M:%S')}: Import from file: #{filo}"
    csv = Parser.new(filo, fno)
    puts "File encoding set as: #{csv.encoding}"
    csv.set_csv_params
    puts "Use comma separator: [#{csv.params[:comm]}]"
    puts "Use quotation marks: [#{csv.params[:quot]}]"
    puts "Fields position: [#{csv.params[:pos].to_s}]"

    db.price = fno
    db.mark_all_for_del
    until csv.filo.eof?
      db.import csv.batch_parse
    end
    csv.close
    db.del_all_marked
  end
  db.close
end

puts "Time spent: #{time.round(2)}"
puts "Memory spend: #{`ps -o rss= -p #{Process.pid}`.to_i / 1024} MB"
