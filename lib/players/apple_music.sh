#!/usr/bin/env bash
# Apple Music player module for now-playing widget

# Check if Apple Music is running
apple_music_is_running() {
  if pgrep -x "Music" > /dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# Check if Apple Music is playing
apple_music_is_playing() {
  state=$(osascript -e 'if application "Music" is running then tell application "Music" to get player state as string' 2>/dev/null)
  if [ "$state" = "playing" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# Get current Apple Music state (closed/paused/playing)
apple_music_get_state() {
  if [ "$(apple_music_is_running)" = "false" ]; then
    echo "closed"
  elif [ "$(apple_music_is_playing)" = "true" ]; then
    echo "playing"
  else
    echo "paused"
  fi
}

# Get current track ID
apple_music_get_track_id_local() {
  track_id=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get id of current track' 2>/dev/null)
  echo "$track_id"
}

# Get current track details from local Apple Music with robust JSON handling
apple_music_get_track_details_local() {
  # Get each value separately to avoid parsing issues
  local track_id=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get id of current track as string' 2>/dev/null)
  local track_name=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get name of current track' 2>/dev/null)
  local artist_name=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get artist of current track' 2>/dev/null)
  local album_name=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get album of current track' 2>/dev/null)

  if [ -n "$track_id" ] && [ -n "$track_name" ]; then
    # Build JSON safely using jq
    track_info=$(jq -n \
      --arg id "$track_id" \
      --arg name "$track_name" \
      --arg artist "$artist_name" \
      --arg album "$album_name" \
      '{track_id: $id, track_name: $name, artist: $artist, album: $album, player: "apple_music"}')

    if [ -n "$track_info" ]; then
      echo "$track_info"
      return 0
    fi
  fi

  echo ""
  return 1
}

# Get artwork for the current track
apple_music_get_artwork() {
  local destination="$1"
  mkdir -p "$(dirname "$destination")" 2>/dev/null || log_fs_warn "Could not create artwork directory $(dirname "$destination")"
  log_fs_debug "Saving Apple Music artwork to: $destination"

  result=$(osascript <<EOF
  tell application "Music"
    try
      if player state is not stopped then
        -- Get raw artwork data and determine format (not used further here)
        set rawData to raw data of artwork 1 of current track
        set savePath to "$destination"
        -- Open the POSIX file for access
        set fileRef to open for access (POSIX file savePath) with write permission
        set eof fileRef to 0
        write rawData to fileRef starting at 0
        close access fileRef
        tell application "System Events"
          if exists file (POSIX file savePath) then
            return "true"
          else
            return "false:file not created"
          end if
        end tell
      else
        return "false:player stopped"
      end if
    on error errMsg
      try
        close access fileRef
      end try
      return "false:" & errMsg
    end try
  end tell
EOF
)

  if [[ "$result" == "true" ]]; then
    if [ -f "$destination" ] && [ -s "$destination" ]; then
      log_fs_debug "Artwork successfully saved to $destination ($(stat -f%z "$destination") bytes)"
      return 0
    else
      log_fs_warn "Artwork file missing or empty after save attempt"
      return 1
    fi
  else
    log_fs_warn "Failed to save artwork: $result"
    return 1
  fi
}

# Get track info for Apple Music
apple_music_get_track_info() {
  local artwork_dir="$1"
  local track_id="$2"  # Simplified parameters

  # Get track details using AppleScript
  track_info=$(apple_music_get_track_details_local)

  if [ -n "$track_info" ]; then
    track_data=$(echo "$track_info" | jq '.')

    # Handle artwork
    artwork_path="$artwork_dir/${track_id}.jpg"

    # Check if artwork exists in cache
    if [ -f "$artwork_path" ] && [ -s "$artwork_path" ]; then
      log_fs_debug "Using cached Apple Music artwork from $artwork_path"
      track_data=$(echo "$track_data" | jq --arg path "$artwork_path" '. + {artwork_url: $path}')
    else
      # Try to get new artwork - suppress mkdir errors
      mkdir -p "$artwork_dir" 2>/dev/null || log_fs_warn "Could not create artwork directory $artwork_dir"
      if apple_music_get_artwork "$artwork_path"; then
        log_fs_debug "Apple Music artwork saved successfully"
        track_data=$(echo "$track_data" | jq --arg path "$artwork_path" '. + {artwork_url: $path}')
      else
        log_fs_warn "Failed to get Apple Music artwork"
      fi
    fi

    # Format JSON before returning
    track_data=$(echo "$track_data" | jq '.')
    echo "$track_data"
    return 0
  fi

  echo ""
  return 1
}
