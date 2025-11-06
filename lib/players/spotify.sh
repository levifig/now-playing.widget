#!/usr/bin/env bash

# Spotify-specific functionality

# Check if Spotify is running
spotify_is_running() {
  local result=$(osascript -e 'if application "Spotify" is running then return "true" else return "false"' 2>/dev/null)
  if [ "$result" = "true" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# Check if Spotify is playing music
spotify_is_playing() {
  local state=$(osascript -e 'if application "Spotify" is running then tell application "Spotify" to player state' 2>/dev/null)
  if [ "$state" = "playing" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# Get current track ID via AppleScript - Extract just the ID portion
spotify_get_track_id() {
  full_id=$(osascript -e 'tell application "Spotify" to id of current track')
  # Parse the full URI format (spotify:track:6rqhFgbbKwnb9MLmUQDhG6) to extract just the ID
  echo "$full_id" | cut -d':' -f3
}

spotify_get_track_details() {
  # Use here-doc with better JSON escaping
  track_info=$(osascript << EOF
tell application "Spotify"
	set track_name to name of current track
	set artist_name to artist of current track
	set album_name to album of current track
	set artwork_url to artwork url of current track

	return "{
    \"track_name\"  :\"" & track_name & "\",
    \"artist\"      :\"" & artist_name & "\",
    \"album\"       :\"" & album_name & "\",
    \"artwork_url\" :\"" & artwork_url & "\"
  }"
end tell
EOF
)

  # Validate JSON before returning
  if ! echo "$track_info" | jq -e '.' >/dev/null 2>&1; then
    log_fs_warn "Invalid JSON from Spotify"
    # Return empty instead of invalid JSON
    echo ""
    return 1
  fi

  echo "$track_info" | jq -r '. | with_entries(select(.value != null))' | jq -c '.' | sed 's/\\\"/\"/g' | sed 's/\\\\//g' | sed 's/\\n/\n/g'
  return 0
}

# Get player state (running, playing/paused)
spotify_get_state() {
  if [ "$(spotify_is_running)" != "true" ]; then
    echo "closed"
  elif [ "$(spotify_is_playing)" != "true" ]; then
    echo "paused"
  else
    echo "playing"
  fi
}

spotify_get_track_info() {
  local artwork_dir="$1"
  local track_id="$2"  # Simplified parameters

  # Get track details using AppleScript
  track_info=$(spotify_get_track_details)

  if [ -n "$track_info" ]; then
    # Add track_id to data
    track_data=$(echo "$track_info" | jq --arg id "$track_id" '. + {track_id: $id}')

    # Handle artwork - prioritize cache, download only if needed
    if [ -n "$track_id" ]; then
      artwork_path="$artwork_dir/${track_id}.jpg"

      # First check if we already have cached artwork
      if [ -f "$artwork_path" ] && [ -s "$artwork_path" ]; then
        # Use cached artwork
        log_fs_debug "Using cached Spotify artwork from $artwork_path"
        track_data=$(echo "$track_data" | jq --arg path "$artwork_path" '. + {artwork_path: $path}')
      else
        # No cached artwork, try to download
        artwork_url=$(echo "$track_data" | jq -r '.artwork_url')
        if [ -n "$artwork_url" ] && [ "$artwork_url" != "null" ]; then
          mkdir -p "$artwork_dir" 2>/dev/null || log_fs_warn "Could not create artwork directory $artwork_dir"
          log_fs_debug "Downloading Spotify artwork from $artwork_url"
          if curl -s "$artwork_url" -o "$artwork_path"; then
            if [ -f "$artwork_path" ] && [ -s "$artwork_path" ]; then
              track_data=$(echo "$track_data" | jq --arg path "$artwork_path" '. + {artwork_path: $path}')
              log_fs_debug "Successfully downloaded and cached Spotify artwork"
            fi
          fi
        fi
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
