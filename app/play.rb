require 'yaml'

# Sets Play up to be used by its friendly friends.
module Play

  # Public: The config located in config/play.yml.
  #
  # Returns an OpenStruct so you can chain methods off of `Play.config`.
  def self.config
    OpenStruct.new \
      :secret        => yaml['gh_secret'],
      :client_id     => yaml['gh_key'],
      :gh_org        => yaml['gh_org'],
      :stream_url    => yaml['stream_url'],
      :office_url    => yaml['office_url'],
      :hostname      => yaml['hostname'],
      :pusher_app_id => yaml['pusher_app_id'],
      :pusher_key    => yaml['pusher_key'],
      :pusher_secret => yaml['pusher_secret'],
      :auth_token    => yaml['auth_token'],
      :spotify_username => yaml['spotify_username'],
      :spotify_playlist => yaml['spotify_playlist'],
      :spotify_access_token => yaml['spotify_access_token'],
      :spotify_refresh_token => yaml['spotify_refresh_token'],
      :spotify_token => yaml['spotify_token'],
      :spotify_client_id => yaml['spotify_client_id'],
      :spotify_client_secret => yaml['spotify_client_secret']
  end

private

  # Load the config YAML.
  #
  # Returns a memoized Hash.
  def self.yaml
    if File.exist?('config/play.yml')
      @yaml ||= YAML.load_file('config/play.yml')
    else
      {}
    end
  end

end
