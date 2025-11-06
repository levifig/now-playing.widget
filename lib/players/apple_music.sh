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
  # Get all values in a single AppleScript call for performance
  # Returns: track_id|track_name|artist|album (pipe-separated)
  local track_data=$(osascript -e 'if application "Music" is running then tell application "Music" to if current track exists then get (id of current track as string) & "|" & (name of current track) & "|" & (artist of current track) & "|" & (album of current track)' 2>/dev/null)

  if [ -n "$track_data" ]; then
    # Split the pipe-separated values
    local track_id=$(echo "$track_data" | cut -d'|' -f1)
    local track_name=$(echo "$track_data" | cut -d'|' -f2)
    local artist_name=$(echo "$track_data" | cut -d'|' -f3)
    local album_name=$(echo "$track_data" | cut -d'|' -f4)

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
  fi

  echo ""
  return 1
}

# Get artwork as base64 data URL
apple_music_get_artwork_data() {
  log_fs_debug "Generating Apple Music artwork data"

  # Extract raw artwork data and convert to base64 data URL
  # AppleScript returns hex data in format «data tdta<hex>»
  # We need to strip the wrapper and convert hex to binary, then base64 encode
  local raw_output=$(osascript -e 'tell application "Music"
    set rawData to raw data of artwork 1 of current track
    return rawData
  end tell' 2>/dev/null)

  if [ -z "$raw_output" ]; then
    log_fs_warn "Failed to get raw artwork data from Apple Music"
    return 1
  fi

  # Strip «data tdta and » wrapper, convert hex to binary, then base64 encode
  # Use -w 0 or -b 0 depending on base64 implementation to prevent line wrapping
  local base64_data=$(echo "$raw_output" | sed 's/«data tdta//' | sed 's/»//' | xxd -r -p | base64 -b 0 2>/dev/null || echo "$raw_output" | sed 's/«data tdta//' | sed 's/»//' | xxd -r -p | base64 | tr -d '\n')

  if [ -n "$base64_data" ]; then
    local data_url="data:image/jpeg;base64,${base64_data}"
    log_fs_debug "Successfully generated artwork data"
    echo "$data_url"
    return 0
  else
    log_fs_warn "Failed to encode artwork data to base64"
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

    # Handle artwork - use data URL directly (no caching for Apple Music)
    artwork_data_url=$(apple_music_get_artwork_data | tr -d '\n\r')

    if [ -n "$artwork_data_url" ]; then
      log_fs_debug "Using Apple Music artwork data"
      track_data=$(echo "$track_data" | jq --arg url "$artwork_data_url" '. + {artwork_url: $url}')
    else
      log_fs_warn "Failed to get Apple Music artwork data"
    fi

    # Format JSON before returning
    track_data=$(echo "$track_data" | jq '.')
    echo "$track_data"
    return 0
  fi

  echo ""
  return 1
}
