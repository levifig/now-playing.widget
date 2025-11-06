#!/usr/bin/env bash

# Common functions used across different player modules

# Initialize cache with size and time limits
init_cache() {
  local cache_dir=$1
  local artwork_dir=$2
  local time_expiration_hours=$3  # Time in hours
  local max_cache_size=$4         # Max size in MB (default 100MB)

  # Set default max cache size if not provided
  max_cache_size=${max_cache_size:-100}

  # Ensure cache directories exist - suppress errors but log them
  mkdir -p "$cache_dir" 2>/dev/null || log_fs_warn "Could not create cache directory $cache_dir"
  mkdir -p "$artwork_dir" 2>/dev/null || log_fs_warn "Could not create artwork directory $artwork_dir"

  # Clean cache based on time and size
  local cleaned_count
  cleaned_count=$(clean_cache "$artwork_dir" "$time_expiration_hours" "$max_cache_size")

  log_fs_debug "Cache initialized with expiration: ${time_expiration_hours}h, max size: ${max_cache_size}MB (cleaned $cleaned_count files)"
}

# Clean cache based on age and total size
clean_cache() {
  local cache_dir="$1"
  local time_expiration_hours="$2"
  local max_size_mb="$3"
  local current_time=$(date +%s)
  local expire_time=$((current_time - time_expiration_hours * 3600))
  local cleaned_files=0

  # Create timestamps if not exists
  touch "$cache_dir/.last_size_check"

  # Only check size every hour to avoid constant disk operations
  # Support both BSD stat (macOS) and GNU stat
  local last_check_time
  if stat --version &>/dev/null; then
    # GNU stat
    last_check_time=$(stat -c "%Y" "$cache_dir/.last_size_check" 2>/dev/null || echo 0)
  else
    # BSD stat (macOS default)
    last_check_time=$(stat -f "%m" "$cache_dir/.last_size_check" 2>/dev/null || echo 0)
  fi

  if [ $(( $(date +%s) - last_check_time )) -gt 3600 ]; then
    log_fs_debug "Checking cache size and expiration"

    # Remove files older than the expiration time (in hours, using -mmin)
    local expired_files
    expired_files=$(find "$cache_dir" -type f -name "*.jpg" -mmin +$((time_expiration_hours * 60)) 2>/dev/null)
    if [ -n "$expired_files" ]; then
      while IFS= read -r file; do
        rm -f "$file"
        cleaned_files=$((cleaned_files + 1))
        log_fs_debug "Removed expired artwork: $file"
      done <<< "$expired_files"
    fi

    # Then check overall cache size and remove oldest files if needed
    local cache_size_kb=$(du -sk "$cache_dir" 2>/dev/null | cut -f1)
    local cache_size_mb=$((cache_size_kb / 1024))

    if [ "$cache_size_mb" -gt "$max_size_mb" ]; then
      log_fs_info "Cache size ($cache_size_mb MB) exceeds limit ($max_size_mb MB), cleaning oldest files"

      # List files by modification time, oldest first, safely (BSD/GNU stat compatible)
      local files_to_remove
      if stat --version &>/dev/null; then
        # GNU stat
        files_to_remove=$(find "$cache_dir" -type f -name "*.jpg" -print0 2>/dev/null | xargs -0 stat -c "%Y %n" 2>/dev/null | sort -n | cut -d' ' -f2- || echo "")
      else
        # BSD stat
        files_to_remove=$(find "$cache_dir" -type f -name "*.jpg" -print0 2>/dev/null | xargs -0 stat -f "%m %N" 2>/dev/null | sort -n | cut -d' ' -f2- || echo "")
      fi
      for file in $files_to_remove; do
        [ -z "$file" ] && continue
        rm -f "$file"
        cleaned_files=$((cleaned_files + 1))
        log_fs_debug "Removed old artwork: $file"
        # Recalculate cache size
        cache_size_kb=$(du -sk "$cache_dir" 2>/dev/null | cut -f1)
        cache_size_mb=$((cache_size_kb / 1024))
        # Stop removing files once we're under the limit
        if [ "$cache_size_mb" -le "$max_size_mb" ]; then
          break
        fi
      done
    fi

    # Update timestamp of last check
    touch "$cache_dir/.last_size_check"
  fi

  # Return number of files cleaned
  echo "$cleaned_files"
}

# Cache artwork and return updated track data
cache_artwork() {
  local artwork_dir=$1
  local track_id=$2
  local track_data=$3

  # Cache artwork if it exists
  local artwork_url=$(echo "$track_data" | jq -r '.artwork_url')
  if [ -n "$artwork_url" ] && [ "$artwork_url" != "null" ]; then
    local artwork_file="$artwork_dir/$track_id.jpg"
    if [ ! -f "$artwork_file" ]; then
      log_fs_debug "Caching artwork for $track_id to $artwork_file"
      curl -s "$artwork_url" -o "$artwork_file"
    fi
    # Update artwork URL to point to local file
    track_data=$(echo "$track_data" | jq --arg path "$artwork_file" '.artwork_url = $path')
  fi

  echo "$track_data"
}

# NOTE: Logging functions have been moved to lib/logging.sh
# init_logging, log_api, log_fs, and other logging functions are now in logging.sh

# Log state changes to avoid spamming logs
# Uses current_track.json instead of separate .state file
log_state_change() {
  local cache_file=$1
  local new_state=$2
  local message=$3

  # Check if cache file exists and has is_playing field
  if [ ! -f "$cache_file" ]; then
    # No cache yet, log the state
    log_api_info "$message"
    log_fs_debug "$message"
    return 0
  fi

  # Get current is_playing state from cache
  local current_is_playing=$(jq -r '.is_playing // "unknown"' "$cache_file" 2>/dev/null)
  local new_is_playing="false"

  # Convert state to is_playing boolean
  if [ "$new_state" = "playing" ]; then
    new_is_playing="true"
  fi

  # Log only if state changed
  if [ "$current_is_playing" != "$new_is_playing" ]; then
    log_api_info "$message"
    log_fs_debug "$message"
    return 0
  fi

  return 1 # No change
}

# Unified track state management with improved JSON handling
update_track_state() {
  local cache_file=$1
  local active_player=$2
  local state=$3  # "playing", "paused", or "closed"
  local track_data="${4:-}"  # Optional - new track data (if we have it)

  # Ensure cache dir exists - suppress errors
  local cache_dir=$(dirname "$cache_file")
  mkdir -p "$cache_dir" 2>/dev/null || log_fs_warn "Could not create cache directory $cache_dir"

  # Set state values based on player state
  local is_playing="false"
  local is_running="true"

  if [ "$state" = "playing" ]; then
    is_playing="true"
  elif [ "$state" = "closed" ]; then
    is_running="false"
  fi

  # Get current Unix timestamp
  local timestamp=$(date +%s)

  # If we have new track data, use it
  if [ -n "$track_data" ]; then
    # First validate that track_data is valid JSON
    if ! echo "$track_data" | jq -e '.' >/dev/null 2>&1; then
      log_fs_warn "Invalid JSON track data received"
      # Create minimal valid JSON
      track_data="{\"error\": \"Invalid JSON data received\"}"
    fi

    # Update with new data and state - format with indentation
    # Reorder fields to put artwork (url/path/data) at the end for better visibility
    echo "$track_data" | jq --arg player "$active_player" \
      --argjson playing "$is_playing" \
      --argjson running "$is_running" \
      --argjson ts "$timestamp" \
      '. as $orig | {
        track_id: .track_id,
        track_name: .track_name,
        artist: .artist,
        album: .album,
        player: $player,
        is_playing: $playing,
        player_running: $running,
        last_updated: $ts
      } + if $orig.artwork_url then {artwork_url: $orig.artwork_url} else {} end + if $orig.artwork_path then {artwork_path: $orig.artwork_path} else {} end' > "$cache_file"
  elif [ -f "$cache_file" ]; then
    # Update existing track data with new state
    if jq -e '.' "$cache_file" >/dev/null 2>&1; then
      local cache_dir=$(dirname "$cache_file")
      local cache_filename=$(basename "$cache_file")
      jq --arg player "$active_player" \
        --argjson playing "$is_playing" \
        --argjson running "$is_running" \
        --argjson ts "$timestamp" \
        '.player = $player | .is_playing = $playing | .player_running = $running | .last_updated = $ts' \
        "$cache_file" > "${cache_dir}/.${cache_filename}.tmp" && mv "${cache_dir}/.${cache_filename}.tmp" "$cache_file"
    else
      log_fs_warn "Invalid JSON in cache file"
      echo "{\"player\": \"$active_player\", \"is_playing\": $is_playing, \"player_running\": $is_running, \"last_updated\": $timestamp}" | jq '.' > "$cache_file"
    fi
  else
    # No track data, create minimal state - properly formatted
    echo "{\"player\": \"$active_player\", \"is_playing\": $is_playing, \"player_running\": $is_running, \"last_updated\": $timestamp}" | jq '.' > "$cache_file"
  fi

  # Always ensure the output is valid and formatted JSON
  if jq -e '.' "$cache_file" >/dev/null 2>&1; then
    cat "$cache_file"
  else
    log_fs_error "Final JSON is invalid"
    echo "{\"error\": \"Invalid JSON data\", \"player\": \"$active_player\"}" | jq '.'
  fi
}

# Check if track has changed
has_track_changed() {
  local cache_file=$1
  local current_track_id=$2

  # If cache doesn't exist or has no track_id, return true (track changed)
  if [ ! -f "$cache_file" ] || ! jq -e '.track_id' "$cache_file" >/dev/null 2>&1; then
    return 0  # true - track changed or no cached track
  fi

  # Compare track IDs
  local cached_id=$(jq -r '.track_id' "$cache_file")
  if [ "$current_track_id" != "$cached_id" ]; then
    return 0  # true - track changed
  fi

  return 1  # false - same track
}

# Ensure valid JSON in the cache file with proper formatting
clean_json_cache() {
  local cache_file=$1

  # If file exists with content
  if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
    # Validate JSON before formatting
    if jq -e '.' "$cache_file" >/dev/null 2>&1; then
      # Format JSON with proper indentation
      local cache_dir=$(dirname "$cache_file")
      local cache_filename=$(basename "$cache_file")
      jq '.' "$cache_file" > "${cache_dir}/.${cache_filename}.tmp" && mv "${cache_dir}/.${cache_filename}.tmp" "$cache_file"
      return 0
    else
      log_fs_error "Invalid JSON in cache file during cleaning"
      return 1
    fi
  fi
  return 1
}
