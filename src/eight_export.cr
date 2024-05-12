require "option_parser"
require "./eight_api.cr"
require "./csv.cr"

struct Arguments
  property from_date : Time?
  property file_path : String

  def initialize(@file_path)
  end
end

arguments = Arguments.new "./entries.csv"

OptionParser.parse do |parser|
  parser.banner = "Usage: eight_export [arguments]"
  parser.on("-f DATE", "--from=DATE", "Export from date (in format %Y-%m-%d)") { |date|
    # TODO: Local timezone
    puts date
    arguments.from_date = Time.parse(date, "%Y-%m-%d", Time::Location::UTC)
  }
  parser.on("-o FILE", "--output=FILE", "Export to file path") { |output_file|
    arguments.file_path = output_file
  }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

csv = CSVFile.new arguments.file_path
client = EightSleep.new
from_date = arguments.from_date || csv.last_date
entries = client.fetch_entries from_date
entries.each do |entry|
  csv.append(entry.date.to_unix, entry.hrv, entry.bpm)
end

puts "Exported entries from #{from_date.to_s("%Y-%m-%d")} to #{arguments.file_path}"
