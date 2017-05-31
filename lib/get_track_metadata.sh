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

get_from_current_track()
{
  osascript << EOF
tell application "Spotify"
  set currentUrl to $1 of current track as string
  return currentUrl
  end tell
EOF
}

get_json()
{
  printf '{
      "artwork_url": "%s",
      "track_name": "%s",
      "artist": "%s",
      "album": "%s"
  }' "$(get_from_current_track "artwork url")" "$(get_from_current_track "name")" "$(get_from_current_track "artist")" "$(get_from_current_track "album")"
}

if [ $check -eq 1 ]; then
  cur_track_json=""
  scriptdir=$( dirname "${BASH_SOURCE[0]}" )

  cur_track_json=$(get_json)

  echo $cur_track_json > $scriptdir/cur_track.json
  echo "$cur_track_json"
else
  exit
fi
