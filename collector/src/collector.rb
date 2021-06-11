#encoding: UTF-8
require "unicode"
$LOAD_PATH << '.' << './lib' << "#{File.dirname(__FILE__)}"
require_relative './lib/data_collect'

RECORDS_DIR = "#{File.dirname(__FILE__)}/../records"
SOURCE_RECORDS_DIR = "#{File.dirname(__FILE__)}/../source_records"

Dir.mkdir("#{RECORDS_DIR}") unless Dir.exists?("#{RECORDS_DIR}")

Dir.glob('#{RECORDS_DIR}/*.xml') do |f|
  File.unlink(f)
end

if ARGV.empty?
  puts "USAGE #{__FILE__} rules"
  exit 1
else
  filename = ARGV[0]
  dc = DataCollect.new
  dc.runner(filename)
end