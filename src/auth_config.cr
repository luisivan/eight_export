AUTH_PATH = "./.auth.yml"

struct Session
  property user_id : String
  property expiration_date : Time
  property token : String

  def initialize(@user_id, @expiration_date, @token)
  end
end

class AuthConfig
  property email : String?
  property password : String?
  property timezone : String
  property session : Session

  def initialize
    @session = Session.new("", Time.unix(0), "")
    @timezone = "Etc/UTC"
    begin
      auth_file = File.read(AUTH_PATH)
      auth_config = YAML.parse(auth_file)
      @email = auth_config["email"].as_s
      @password = auth_config["password"].as_s
      @timezone = auth_config["timezone"].as_s
      if auth_config["session"]?
        session_config = auth_config["session"]
        @session = Session.new(session_config["user_id"].as_s, Time.unix(session_config["expiration_date"].as_i), session_config["token"].as_s)
      end
    rescue ex
      puts "Please place your Eight Sleep email and password in #{AUTH_PATH}"
      Process.exit
    end
  end

  def save_session(session : Session)
    File.write(AUTH_PATH, {email: @email, password: @password, timezone: @timezone, session: {user_id: session.user_id, expiration_date: session.expiration_date.to_unix, token: session.token}}.to_yaml)
    @session = session
  end
end
