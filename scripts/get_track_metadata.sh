#!/bin/bash

check=`ps -ef | grep "Spotify.app/Contents/MacOS/Spotify" | grep -v "grep" | wc -l | cut -d " " -f8`

get_track_id()
{
  osascript << EOF
tell application "Spotify"
  set spotify_url to id of current track
	set track_id to do shell script "echo " & quoted form of spotify_url & " | cut -d \":\" -f3"
  return track_id
end tell
EOF
}

if [ $check -eq 1 ]; then
  track_id=$(get_track_id)
  curl -s -X GET "https://api.spotify.com/v1/tracks/$track_id"
else
  exit
fi
