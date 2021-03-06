require 'uri'
require 'logger'

logger = Logger.new(STDOUT)

def reload!
  puts "Reloading #{ENV.fetch('ENV')} environment"
  load './bootup.rb'
end

def current_user
  if request.cookies['uid'] && request.cookies['cookie_key']
    User.where("uid = :uid AND cookie_keys @> :cookie_key", {uid: request.cookies['uid'], cookie_key: [{cookie_key: request.cookies['cookie_key']}].to_json }).first
  end
end

def find_user(screen_name)
  User.find_by(screen_name: screen_name)
end

def expand_url(url)
  result = Curl::Easy.perform(url) do |curl|
    curl.head = true
    curl.headers["User-Agent"] = "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:80.0) Gecko/20100101 Firefox/80.0"
    curl.verbose = true
    curl.follow_location = true
  end
  result.last_effective_url
end

def preferred_fav_icon(url, filepath: "config/favicon.yml")
  favicon = YAML.load_file filepath if File.exists? filepath
  uri = URI.parse(url)
  hostname = uri.host.gsub("www.", "")
  second_hostname  =  uri.host.split(".").drop(1).join(".")
  
  if hostname && favicon.to_h[hostname] 
    favicon.to_h[hostname] 
  elsif second_hostname && favicon.to_h[second_hostname] 
    favicon.to_h[second_hostname] 
  else
    uri.scheme = "https"
    uri.to_s
  end
end

def download_file(url, path="/public/cache/")
  filename = File.basename(url).split("?").first
  filepath = "#{path}#{filename}"
  
  URI.open(url) do |image|
    File.open(filepath.slice(1..-1), "wb") do |file|
      file.write(image.read)
    end
  end
  filepath.gsub("/public/", "/")
end

def invalidate_browser_id_cookie(browser_id)
  user = current_user
  previous_cookie_list = user.cookie_keys
  cookie_to_delete = { browser_id: browser_id }
  
  new_cookie_list = delete_active_cookie(previous_cookie_list, cookie_to_delete)
  
  user.cookie_keys = new_cookie_list
  user.save!
end

def delete_active_cookie(previous_cookie_list, cookie_to_delete)
  new_cookie_list = []

  previous_cookie_list.each do |c|
    if c['browser_id'] == cookie_to_delete[:browser_id]
      next
    end
    new_cookie_list << c
  end
    
  new_cookie_list
end

def add_or_update_active_cookies(previous_cookie_list, new_cookie)
  new_cookie_list = []

  if previous_cookie_list.select{|c|c[:browser_id] == new_cookie[:browser_id]}.length > 0
    # Update
    previous_cookie_list.each do |c|
      current = c
      if c[:browser_id] == new_cookie[:browser_id]
        current = new_cookie
      end
      new_cookie_list << current
    end
  else
    # New
    new_cookie_list =  previous_cookie_list
    new_cookie_list << new_cookie
  end
    
  new_cookie_list
end



def format_datetime(datetime, timezone)
  if valid_timezone(timezone)
    datetime.getlocal(timezone).strftime('%b %-d, %Y %l:%M%P')
  else
    datetime.strftime('%b %-d, %Y')
  end
end

def browser_fingerprint
  # basic finger printing. the cookie is the real unique
  # value. but this is for extra measure to make it easier
  # to identify which browser we are signing out when we
  # destroy sessions
  Digest::SHA256.hexdigest "#{request.env['HTTP_USER_AGENT']}#{request.env['REMOTE_ADDR']}#{request.env['APP_ENCRYPTION_KEY']}"
end

def prettify_user_agent(user_string)
  user_agent = UserAgentParser.parse user_string
  operating_system = user_agent.os
  "#{operating_system.to_s} <br> #{user_agent.to_s}"  
end


def prettify_datetime(datetime)
  if !datetime
    return ""
  end
  
  d = datetime
  if d.class == String
    d = DateTime.parse(datetime)
  end
  d.strftime('%b %-d, %Y %l:%M%P')
end

def valid_timezone(timezone)
  timezone.to_s.match(/[\-\+]\d\d\:\d\d/)
end

def reading_time(text)
   time = text.split(" ").count / 250
   "#{time} minute#{'s' if time > 2}"
end

def cli_column(text, cols=20)
  text.to_s.ljust(cols)
end

def is_numeric?(string)
  begin
    Float(string)
  rescue
    false # not numeric
  else
    true # numeric
  end
end

def is_boolean_string(text)
  text == "true" || text == "false"
end

def string_to_boolean(text)
  text == "true"
end

def simple_text(text)
  text.gsub(/[^a-zA-Z_]/, "").to_s
end

def valid_twitter_handle?(text)
  text.match(/^@?(\w){1,15}$/)
end

def render_partial(filename)
  html = File.open("#{APP_ROOT}/views/partials/#{filename}.erb").read
  template = ERB.new(html)
  template.result
end