require 'rspotify'

module Play
  class Player

    # The application we're using. iTunes, dummy.
    #
    # Returns an Appscript instance of the music app.
    def self.app
      Appscript.app('Spotify')
    end

    # All songs in the library.
    def self.library
      app.playlists['Library'].get
    end

    def self.spotify_playlist_uri
      Queue.playlist.uri
    end

    # Play the music.
    def self.play
      if now_playing.nil?
        app.play_track(spotify_playlist_uri)
      elsif !Queue.queued?(now_playing)
        app.play_track(spotify_playlist_uri)
      else
        app.play
      end
    end

    # Pause the music.
    def self.pause
      app.pause
    end

    # Is there music currently playing?
    def self.paused?
      state = app.player_state.get
      state == :paused
    end

    # Maybe today is the day the music stopped.
    def self.stop
      pause if not paused?
    end

    # Play the next song.
    #
    # Returns the new song.
    def self.play_next
      if Queue.queued?(now_playing)
        Play::Queue.clear_up_to_next_track()
        app.play_track(spotify_playlist_uri)
      else
        app.next_track
      end
      now_playing
    end

    # Play the previous song.
    def self.play_previous
      app.previous_track
    end

    # Get the current numeric volume.
    #
    # Returns an Integer from 0-100.
    def self.system_volume
      `osascript -e 'get output volume of (get volume settings)'`.chomp.to_i
    end

    # Set the system volume.
    #
    # setting - An Integer value between 0-100, where 100% is loud and, well, 0
    #           is for losers in offices that are boring.
    #
    # Returns the current volume setting.
    def self.system_volume=(setting)
      `osascript -e 'set volume output volume #{setting}' 2>/dev/null`
      setting
    end

    # Get the current numeric volume.
    #
    # Returns an Integer from 0-100.
    def self.app_volume
      app.sound_volume.get
    end

    # Set the app volume.
    #
    # setting - An Integer value between 0-100, where 100% is loud and, well, 0
    #           is for losers in offices that are boring.
    #
    # Returns the current volume setting.
    def self.app_volume=(setting)
      app.sound_volume.set(setting)
      setting
    end

    # Say something. Robots can speak too, you know.
    #
    # Thirds the volume, does its thing, brings the volume up again, and
    # returns the current volume.
    def self.say(message)
      previous = self.app_volume
      self.app_volume = self.app_volume/3
      `say #{message}`
      self.app_volume = previous
    end

    # Currently-playing song.
    #
    # Returns a Song.
    def self.now_playing
      Song.initialize_from_record(app.current_track)
    rescue Appscript::CommandError
      nil
    end

    # Search all songs for a keyword.
    #
    # Search workflow:
    #   - Search for exact match on Artist name.
    #   - Search for exact match on Song title.
    #   - Search for fuzzy match on Song title.
    #
    # keyword - The String keyword to search for.
    #
    # Returns an Array of matching Songs.
    def self.search(keyword)

      # Song and artist match
      song_title, song_artist = keyword.split(" by ")
      if not song_artist.nil?
        tracks = RSpotify::Track.search(song_title)
        filtered_tracks = tracks.select do |t|
          t.artists.first.name.downcase == song_artist.downcase and
            t.name.downcase == song_title.downcase
        end
        if not filtered_tracks.empty?
          return [Song.initialize_from_api(filtered_tracks.first)]
        end
      end

      # Exact Artist match.
      artists = RSpotify::Artist.search(keyword)
      if not artists.empty?
        tracks = artists.first.top_tracks(:US)
        if not tracks.empty?
          return tracks.map{|t| Song.initialize_from_api(t)}
        end
      end

      # Song match
      tracks = RSpotify::Track.search(keyword)
      if not tracks.empty?
        return [Song.initialize_from_api(tracks.first)]
      end

      #songs = library.tracks[Appscript.its.artist.eq(keyword)].get 
      #return songs.map{|record| Song.new(record.persistent_ID.get)} if songs.size != 0

      # Exact Album match.
      #songs = library.tracks[Appscript.its.album.eq(keyword)].get
      #return songs.map{|record| Song.new(record.persistent_ID.get)} if songs.size != 0

      # Exact Song match.
      #songs = library.tracks[Appscript.its.name.eq(keyword)].get
      #return songs.map{|record| Song.new(record.persistent_ID.get)} if songs.size != 0

      # Fuzzy Song match.
      #songs = library.tracks[Appscript.its.name.contains(keyword)].get
      #songs.map{|record| Song.new(record.persistent_ID.get)}
    end

  end
end
