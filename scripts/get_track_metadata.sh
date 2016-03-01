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
  cur_track_json=""
  scriptdir=$( dirname "${BASH_SOURCE[0]}" )
  if [ -f "$scriptdir/cur_track.id" ]; then
    cur_track_id=`cat $scriptdir/cur_track.id`
  else
    cur_track_id=""
  fi
  if [ "$track_id" == "$cur_track_id" ] && [ -f "$scriptdir/cur_track.json" ]; then
    cur_track_json=`cat $scriptdir/cur_track.json`
  else
    cur_track_json=`curl -s -X GET "https://api.spotify.com/v1/tracks/$track_id"`
    echo $track_id > $scriptdir/cur_track.id
    echo $cur_track_json > $scriptdir/cur_track.json
  fi
  echo "$cur_track_json"
else
  exit
fi
