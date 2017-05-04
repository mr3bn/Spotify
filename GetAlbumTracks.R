library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)

uth.url <- "https://accounts.spotify.com/api/token?grant_type=client_credentials"

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

album <- "5yMCA6HdFAeL1aqUjxO3MO"

url <- paste0("https://api.spotify.com/v1/albums/", album, "/tracks")

response <- GET(paste0("https://api.spotify.com/v1/albums/", album, "/tracks"), add_headers(Authorization = token.header))

tracks.text <- fromJSON(content(response, as="text"))

tracks.comma <- ""

for(i in 1:nrow(tracks.text$items)) {
  if(i == 1) {
    tracks.comma <- tracks.text$items[i,]$id
  }
  else {
    tracks.comma <- paste0(tracks.comma, ",", tracks.text$items[i,]$id)
  }
}

multi.response <- GET(paste0("https://api.spotify.com/v1/tracks/?=ids=", tracks.comma))

multi.text <- fromJSON(content(multi.response, as="text"))