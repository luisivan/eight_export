require "csv"

struct Entry
  property date : Time
  property hrv : Float64
  property bpm : Float64

  def initialize(@date, @hrv, @bpm)
  end
end

CSV_HEADERS = ["Date", "HRV", "BPM"]

class CSVFile
  property file : File
  property last_date : Time
  property headers_added : Bool

  def initialize(file_path)
    @last_date = Time.local
    csv_contents = CSV_HEADERS.join(",")
    if File.exists?(file_path)
      csv_contents = File.read(file_path)
    end
    csv = CSV.parse(csv_contents)
    if File.exists?(file_path) && csv[-1]?
      @last_date = Time.parse(csv[-1][0], "%Y-%m-%d", Time::Location::UTC)
    end
    @file = File.open(file_path, "w")
    @headers_added = false
  end

  def append(date, hrv, bpm)
    CSV.build(@file) do |csv|
      if !@headers_added
        csv.row CSV_HEADERS[0], CSV_HEADERS[1], CSV_HEADERS[2]
        @headers_added = true
      end
      formatted_date = date.to_s("%Y-%m-%d %H:%M:%S %z")
      formatted_hrv = hrv.round.format(decimal_places: 0)
      formatted_bpm = bpm.round.format(decimal_places: 0)
      csv.row formatted_date, formatted_hrv, formatted_bpm
    end
  end
end
