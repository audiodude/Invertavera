require 'sinatra'
require 'httparty'
require 'facets/string/titlecase'

def load_genres
  response = HTTParty.get('http://developer.echonest.com/api/v4/artist/list_genres?api_key=R8L4TX8MCPXTIOYKW&format=json')
  response['response']['genres'].collect { |g| g['name'] }
end

def load_artists_for_genre(genre)
  response = HTTParty.get("http://developer.echonest.com/api/v4/artist/top_hottt?api_key=R8L4TX8MCPXTIOYKW&format=json&results=50",
                          {:query => {'genre'=>genre}})
  response['response']['artists']
end

def load_bio(name)
  response = HTTParty.get('http://api.rovicorp.com/data/v1/name/musicbio?apikey=4249bvjq9hn3phhw6x8wm6k7',
                          {:query => {
                              'name'=>name,
                              'sig'=>Digest::MD5.hexdigest('4249bvjq9hn3phhw6x8wm6k7' + 'fDPFcmNXay' + Time.now.to_i.to_s)}})
  response['musicBio']['text']
end

def treat_bio(bio, chosen_name, bio_name)
  rovi_link = /\[roviLink="[^"]+"\]([^\[]+)\[\/roviLink\]/
  italic = /\[muzeItalic\]([^\[]+)\[\/muzeItalic\]/
  bio.gsub!(rovi_link, '\1')
  bio.gsub!(italic, '\1')
  bio.gsub!(bio_name, chosen_name)
  
  chosen_last = chosen_name.split(' ')[-1]
  bio_last = bio_name.split(' ')[-1]
  bio.gsub!(bio_last, chosen_last)

  return bio
end

def load_song(chosen_id)
  response = HTTParty.get('http://developer.echonest.com/api/v4/song/search?api_key=R8L4TX8MCPXTIOYKW&format=json'+
                          '&results=1&sort=song_hotttnesss-desc&bucket=id:rdio-WW&bucket=tracks&limit=true',
                          :query => {'artist_id' => chosen_id})
  response['response']['songs'][0]['tracks'][0]['foreign_id']
end

get '/' do
  @genres = load_genres
  erb :index
end

get '/helper.html' do
  erb :helper, :layout => false
end

get '/play' do
  genres = load_genres
  genre_hash = Hash[ genres.map{ |g| [g.gsub(' ', '-'), g] } ]
  @genre = genre_hash[params[:genre]]

  artists = load_artists_for_genre(@genre)

  @chosen_artist, @bio_artist = artists.sample(2)
  if rand(1000) >= 500
    @bio_artist = @chosen_artist
  end

  @bio = load_bio(@bio_artist['name'])
  @bio = treat_bio(@bio, @chosen_artist['name'], @bio_artist['name'])

  @rdio_id = load_song(@chosen_artist['id'])
  erb :play
end
