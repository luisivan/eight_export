require "crest"
require "json"
require "csv"
require "time"
require "yaml"
require "option_parser"
require "./auth_config"
require "./csv"

# Reverse engineered from the Eight Sleep app
CLIENT_ID      = "0894c7f33bb94800a03f1f4df13a4f38"
CLIENT_SECRET  = "f0954a3ed5763ba3d06834c73731a32f15f168f47d4f164751275def86db0c76"
CLIENT_API_URL = "https://client-api.8slp.net/v1"
AUTH_URL       = "https://auth-api.8slp.net/v1/tokens"

DEFAULT_API_HEADERS = {
  "Content-Type"    => "application/json",
  "Host"            => "client-api.8slp.net",
  "Connection"      => "keep-alive",
  "User-Agent"      => "okhttp/4.9.3",
  "Accept-Encoding" => "gzip",
  "Accept"          => "application/json",
}

struct Entry
  property date : Time
  property hrv : Float64
  property bpm : Float64

  def initialize(@date, @hrv, @bpm)
  end
end

class EightSleep
  property api : Crest::Resource
  property entries : Array(Entry)

  def initialize
    @api = Crest::Resource.new(CLIENT_API_URL, headers: DEFAULT_API_HEADERS, handle_errors: false)
    @entries = Array(Entry).new
    @auth_config = AuthConfig.new
    if @auth_config.session.token.empty? || @auth_config.session.expiration_date.to_unix < Time.local.to_unix
      self.auth
    end
    DEFAULT_API_HEADERS.merge({"Authorization" => "Bearer #{@auth_config.session.token}"})
    @api = Crest::Resource.new(CLIENT_API_URL, headers: DEFAULT_API_HEADERS, handle_errors: false)
  end

  def auth
    puts "Authenticating"
    response = Crest.post(AUTH_URL,
      {
        "client_id"     => CLIENT_ID,
        "client_secret" => CLIENT_SECRET,
        "grant_type"    => "password",
        "username"      => @auth_config.email,
        "password"      => @auth_config.password,
      }
    )
    json = JSON.parse(response.body).as_h
    expiration_date = Time.local + Time::Span.new(seconds: json["expires_in"].as_i, nanoseconds: 0)
    session = Session.new(json["userId"].as_s, expiration_date, json["access_token"].as_s)
    @auth_config.save_session(session)
  end

  def fetch_entries(from : Time) : Array(Entry)
    today = Time.local

    response = @api["/users/#{@auth_config.session.user_id}/trends"].get(headers: {"Authorization" => "Bearer #{@auth_config.session.token}"}, params: {
      "tz"                   => @auth_config.timezone,
      "from"                 => from.to_s("%Y-%m-%d"),
      "to"                   => today.to_s("%Y-%m-%d"),
      "include-main"         => "true",
      "include-all-sessions" => "false",
      "model-version"        => "v2",
    }) do |resp|
      output = Compress::Gzip::Reader.new resp.body_io
      days = JSON.parse(output).as_h["days"].as_a
      days.each do |day|
        date = Time.parse(day["day"].as_s, "%Y-%m-%d", Time::Location::UTC)
        sleep_data = day["sleepQualityScore"].as_h
        hrv = sleep_data["hrv"].as_h["average"].as_f
        bpm = sleep_data["heartRate"].as_h["average"].as_f

        entry = Entry.new date, hrv, bpm
        @entries << entry
      end
    end
    return @entries
  end
end
