#!/bin/bash

# Directory where this script is located
scriptdir=$( dirname "${BASH_SOURCE[0]}" )

# Spotify API credentials - replace with your own
CLIENT_ID="YOUR_CLIENT_ID"
CLIENT_SECRET="YOUR_CLIENT_SECRET"

# Check if Spotify is running
check=`ps -ef | grep "Spotify.app/Contents/MacOS/Spotify" | grep -v "grep" | wc -l | cut -d " " -f8`

# Get the current track ID from Spotify
get_track_id() {
  osascript << EOF
tell application "Spotify"
  set spotify_url to id of current track
  set track_id to do shell script "echo " & quoted form of spotify_url & " | cut -d \":\" -f3"
  return track_id
end tell
EOF
}

# Get an access token from Spotify
get_access_token() {
  token_response=$(curl -s -X "POST" -H "Authorization: Basic $(echo -n $CLIENT_ID:$CLIENT_SECRET | base64)" -d "grant_type=client_credentials" https://accounts.spotify.com/api/token)
  echo $(echo $token_response | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
}

if [ $check -eq 1 ]; then
  track_id=$(get_track_id)
  cur_track_json=""
  
  # Check if we already have this track's info cached
  if [ -f "$scriptdir/cur_track.id" ]; then
    cur_track_id=`cat $scriptdir/cur_track.id`
  else
    cur_track_id=""
  fi
  
  if [ "$track_id" == "$cur_track_id" ] && [ -f "$scriptdir/cur_track.json" ]; then
    cur_track_json=`cat $scriptdir/cur_track.json`
  else
    # Get an access token
    access_token=$(get_access_token)
    
    # Get track info with authentication
    cur_track_json=`curl -s -X GET "https://api.spotify.com/v1/tracks/$track_id" -H "Authorization: Bearer $access_token"`
    
    # Cache the results
    echo $track_id > $scriptdir/cur_track.id
    echo $cur_track_json > $scriptdir/cur_track.json
  fi
  
  echo "$cur_track_json"
else
  exit
fi
