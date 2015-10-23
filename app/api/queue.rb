module Play
  # API endpoints dealing with managing your Queue.
  class App < Sinatra::Base

    get "/queue" do
      songs_as_json(Queue.songs,current_user)
    end

    post "/queue" do
      if params[:id]
        song = Song.find(params[:id])
      else
        song = Song.new(:name => params[:name], :artist => params[:artist])
      end
      Queue.add_song(song)
      History.add(song,current_user)
      true
    end

    delete "/queue" do
      if params[:id]
        song = Song.find(params[:id])
      else
        song = Song.new(:name => params[:name], :artist => params[:artist])
      end
      Queue.remove_song(song)
      true
    end

    delete "/queue/all" do
      Queue.clear
      true
    end

    post "/queue/stars" do
      songs = current_user.stars.shuffle[0..4]
      songs.each do |song|
        Queue.add_song(song)
        History.add(song,current_user)
      end

      songs_as_json(songs,current_user)
    end

    post "/freeform" do
      subject = params[:subject]

      if subject.end_with?(" right now")
        subj = subject.split(" right now").first
        songs = Player.search(subj)
        if songs.size > 0
          song = songs.first
          Queue.add_song_now(song)
          History.add(song,current_user)
          sleep 2
          Player.play_next
          return songs_as_json([song],current_user)
        end
      end

      songs = Player.search(subject)
      if songs.size > 0
        songs.each do |song|
          Queue.add_song(song)
          History.add(song,current_user)
        end
        return songs_as_json(songs,current_user)
      end

      # Do we have an Artist match?
      songs = Artist.new(subject).songs
      if songs.size > 0
        songs = songs.shuffle[0..9]
        songs.each do |song|
          Queue.add_song(song)
          History.add(song,current_user)
        end
        return songs_as_json(songs,current_user)
      end

      # No? Maybe we have an album.
      songs = Album.songs_by_name(subject)
      if songs.size > 0
        songs.each do |song|
          Queue.add_song(song)
          History.add(song,current_user)
        end
        return songs_as_json(songs,current_user)
      end

      # Well maybe the shit's just a song.
      song = Song.find_by_name(subject)
      if song
        Queue.add_song(song)
        History.add(song,current_user)
        return songs_as_json([song],current_user)
      end
    end

  end
end
