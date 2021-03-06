require 'open-uri'
require 'cinch'
require 'json'
require 'pp' # We like pretty stuff!

class Spotify
  include Cinch::Plugin

  listen_to :channel
  
  # Structs to hold song info.
  class Song < Struct.new(:artist, :album, :name, :length, :released)
  end 
  
  class Artist < Struct.new(:name)
  end
  
  class Album < Struct.new(:artist, :name, :released)
  end
  
  # Fetch data from spotify API based on URL given.
  def fetch_data(url)
    url = open("http://ws.spotify.com/lookup/1/.json?uri=#{URI.escape(url)}").read
    data = JSON.parse(url)
    return data
    rescue OpenURI::HTTPError
      raise 'Impending doom, catastrophic failure.'
  end # fetch_data
  # Parse track links
  def parse_track(url)
    data = fetch_data(url)
    track = data['track'] # all the fun bits are in 'track'
   # pp data['track']['artists'].first['name']
    artist = track['artists'].first['name']
    album = track['album']['name']
    released = track['album']['released']
    length = (track['length'] / 60).round # Get ca. length of song
    name = track['name']
    s = Song.new(artist, album, name, length, released) # Fill the struct and return the goods!
    return s  
  end # parse_track
  
  # Parse artist links
  def parse_artist(url)
     data = fetch_data(url)
     name = data['artist']['name']
     a = Artist.new(name)
     return a  
   end # parse_artist
   
   # Parse album links
   def parse_album(url)
      data = fetch_data(url)
      album = data['album']
      name = album['name']
      artist = album['artist']
      released = album['released']
      a = Album.new(artist, name, released)
      return a  
    end # parse_album

  def listen(m)
    urls = URI.extract(m.message, "http")
    # handle the urls
    urls.each do |url|
      if url =~ /^http:\/\/open\.spotify\.com\/(.+)\/.+$/ then
        case $1
          when 'track'
           puts "url: #{url.inspect}"
           song = parse_track(url)
           m.reply "Spotify song: #{song.artist} - #{song.album} (#{song.released}) - #{song.name} - ca. #{song.length} minutes long."
          when 'artist'
            artist = parse_artist(url)
            m.reply "Spotify artist: #{artist.name}"
          when 'album'
            album = parse_album(url)
            m.reply "Spotify album: #{album.artist} - #{album.name} (#{album.released})"
        end
      end
    end # urls.each
    # annoying to do this twice, not very DRY
    if m.message =~ /spotify:(.+):.+/ then
      case $1
        when 'track'
         song = parse_track(m.message)
         m.reply "Spotify song: #{song.artist} - #{song.album} (#{song.released}) - #{song.name} - ca. #{song.length} minutes long."
        when 'artist'
          artist = parse_artist(m.message)
          m.reply "Spotify artist: #{artist.name}"
        when 'album'
          album = parse_album(m.message)
          m.reply "Spotify album: #{album.artist} - #{album.name} (#{album.released})"
      end
    end
  end # listen
end # Spotify
