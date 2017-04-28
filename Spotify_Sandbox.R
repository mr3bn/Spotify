  library(httr)
  library(jsonlite)
  library(dplyr)
  library(ggplot2)
  
  #initial call to get authorization token
  auth.url <- "https://accounts.spotify.com/api/token?grant_type=client_credentials"
  
  client.id <- "c755cb9b63d748b9bbe6b84de1e3d0a9"
  client.secret <- "710db386e7d54f819846e26752a3ccf9"
  
  auth.response <- POST(
    auth.url,
    accept_json(),
    authenticate(client.id, client.secret),
    body = list(grant_type = 'client_credentials'),
    encode = 'form'
  )
  
  #this token will need to be included in the header of any requests to the API
  token <- content(auth.response)$access_token
  token.header <- paste0("Bearer ", token)
  
  # table for users id's and their names:
  user.name.list <- c("Mark", "Sonia", "Ann", "MaryBeth", "Erica", "Luis", "Augie", "Jake", "Brice") 
  user.id.list <- c("mark.rossi.06", "122715968", "121619510", "mbdesrosiers", "emstuke", "luisortiz87", "1213855256", "122364140", "12166944716")
  
  users <- data.frame(name=user.name.list, id=user.id.list, stringsAsFactors = FALSE)
  
  for(u in 1:nrow(users)) {
    
    user.id <- users[u, "id"]
    
    playlist.url <- paste0("https://api.spotify.com/v1/users/", user.id, "/playlists")
    
    playlist.response <- GET(playlist.url, add_headers(Authorization = token.header))
    
    playlist.text <- fromJSON(content(playlist.response, as="text"))
    #most of these calls come wrapped in a paging object
    #the meat of what we want will be in the 'items' list of that object
    all.playlists <- playlist.text$items
    
    #create a data frame to hold all this info
    playlist.songs <- data.frame(
      p.name=character(0), 
      p.user=character(0),
      p.user.id=character(0),
      p.id=character(0), 
      p.owner=character(0),
      track.name=character(0),
      track.id=character(0),
      added.at=character(0),
      track.duration=numeric(0),
      track.popularity=numeric(0),
      track.dance=numeric(0),
      track.energy=numeric(0), 
      track.key=integer(0),
      track.loudness=numeric(0), 
      track.speechiness=numeric(0), 
      track.acousticness=numeric(0), 
      track.instrumentalness=integer(0), 
      track.liveness=numeric(0),
      track.valence=numeric(0), 
      track.tempo=numeric(0),
      stringsAsFactors = FALSE
    )
    
    #iterate over the playlists to scrape their individual songs
    for(i in 1:nrow(all.playlists)) {
      p <- all.playlists[i, ]
      
      #spotify was nice enough to include the API url for each track contained inside the playlist$tracks list
      tracks.url <- p$tracks$href
      
      tracks.response <- GET(tracks.url, add_headers(Authorization = token.header))
      
      tracks.text <- fromJSON(content(tracks.response, as="text"))
      tracks <- tracks.text$items
      
      for(j in 1:nrow(tracks)) {
        
        playlist.track <- tracks[j, ]
        
        t <- playlist.track$track
        
        # during prototyping ran into a case where a song came back NA (maybe a local track on the user's playlist)
        # features request will come back 400 error and throw an error when we try to add to all.playlists
        # ....so, pass up this song if it comes back NA from the tracks request
        if(is.na(t$id)) next
        
        # and finally, we arrive at the audio features object:
        features.url <- paste0("https://api.spotify.com/v1/audio-features/", t$id)
        features.response <- GET(features.url, add_headers(Authorization = token.header))
        features <- fromJSON(content(features.response, as="text"))
        
        v = data.frame(
          p.name=p$name,
          p.user=users[u,"name"],
          p.user.id=users[u,"id"],
          p.id=p$id, 
          p.owner=p$owner$id, 
          track.name=t$name, 
          track.id=t$id, 
          added.at=playlist.track$added_at, 
          track.duration=t$duration, 
          track.popularity=t$popularity, 
          track.dance=features$danceability,       
          track.energy=features$energy, 
          track.key=features$key, 
          track.loudness=features$loudness, 
          track.speechiness=features$speechiness, 
          track.acousticness=features$acousticness, 
          track.instrumentalness=features$instrumentalness, 
          track.liveness=features$liveness,       
          track.valence=features$valence, 
          track.tempo=features$tempo,
          stringsAsFactors = FALSE
        )
        
        playlist.songs <- bind_rows(playlist.songs,v)
      } # end tracks loop 
    } # end playlists loop
    
    assign(tolower(users[u, "name"]), playlist.songs)
    
    write.csv(playlist.songs, file=paste0(users[u, "name"], ".csv")) 
    write.csv(playlist.songs, file="all.csv", append=TRUE)
  } # end users loop