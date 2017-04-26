library(httr)
library(jsonlite)
library(dplyr)

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

#get a user's playlists
user.id <- "mtenny12"

https://open.spotify.com/user/

playlist.url <- paste0("https://api.spotify.com/v1/users/", user.id, "/playlists")

playlist.response <- GET(playlist.url, add_headers(Authorization = token.header))

playlist.text <- fromJSON(content(playlist.response, as="text"))
#most of these calls come wrapped in a paging object
#the meat of what we want will be in the 'items' list of that object
all.playlists <- playlist.text$items

#create a data frame to hold all this info
all.songs <- data.frame()


#iterate over the playlists to scrape their individual songs
for(i in 1:nrow(all.playlists)) {
  p <- all.playlists[i, ]
  
  #spotify was nice enough to include the API url for each track contained inside the playlist$tracks list
  tracks.url <- p$tracks$href
  
  tracks.response <- GET(tracks.url, add_headers(Authorization = token.header))
  
  tracks.text <- fromJSON(content(tracks.response, as="text"))
  tracks <- tracks.text$items
  
  print(p$name)
  
  for(j in 1:nrow(tracks)) {
    #print(paste0("Track ", j, " on ", p$name, ": ", tracks[j,"track"]$name))
  }
}