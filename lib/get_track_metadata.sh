#!/usr/bin/env bash
set -euo pipefail

# Main script to fetch track metadata
# This is designed to be modular for supporting multiple music players

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Load logging system
source "$SCRIPT_DIR/logging.sh"

# Load common functions
source "$SCRIPT_DIR/common.sh"

# Cache settings
CACHE_DIR="$(dirname "$SCRIPT_DIR")/cache"
CURRENT_TRACK_FILE="$CACHE_DIR/current_track.json"
ARTWORK_DIR="$CACHE_DIR/artwork"
AUTH_FILE="$CACHE_DIR/auth.json"
CACHE_EXPIRATION=24       # Cache expiration time in hours
MAX_CACHE_SIZE=100        # Maximum cache size in MB

# Logging settings
LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"
API_LOG="$LOG_DIR/api.log"
FS_LOG="$LOG_DIR/filesystem.log"

# Player priority - first player in list gets priority when multiple are playing
PLAYER_PRIORITY=("spotify" "apple_music")

# Initialize logging
init_logging "$LOG_DIR" "$API_LOG" "$FS_LOG"

# Load player modules (all available players) with error handling
if [ -f "$SCRIPT_DIR/players/spotify.sh" ]; then
  source "$SCRIPT_DIR/players/spotify.sh"
else
  log_fs_warn "spotify.sh not found"
fi
if [ -f "$SCRIPT_DIR/players/apple_music.sh" ]; then
  source "$SCRIPT_DIR/players/apple_music.sh"
else
  log_fs_warn "apple_music.sh not found"
fi
# Future: source "$SCRIPT_DIR/players/youtube_music.sh" if present

# ENV_FILE support removed - use config.sh and NOW_PLAYING_CONFIG_FILE instead

# Initialize cache directories with expiration settings
init_cache "$CACHE_DIR" "$ARTWORK_DIR" "$CACHE_EXPIRATION" "$MAX_CACHE_SIZE"

# Determine which player to show based on running state and priority
determine_active_player() {
  local playing_players=()
  local running_players=()

  # Check status for each player
  for player in "${PLAYER_PRIORITY[@]}"; do
    case "$player" in
      "spotify")
        if [ "$(spotify_is_running)" = "true" ]; then
          running_players+=("spotify")
          if [ "$(spotify_is_playing)" = "true" ]; then
            playing_players+=("spotify")
          fi
        fi
        ;;
      "apple_music")
        if [ "$(apple_music_is_running)" = "true" ]; then
          running_players+=("apple_music")
          if [ "$(apple_music_is_playing)" = "true" ]; then
            playing_players+=("apple_music")
          fi
        fi
        ;;
      # Future players here
    esac
  done

  # Decision logic:
  # 1. If any player is playing, choose the highest priority one
  if [ ${#playing_players[@]} -gt 0 ]; then
    # Return the first playing player in the priority list
    for player in "${PLAYER_PRIORITY[@]}"; do
      if [[ " ${playing_players[*]} " =~ " $player " ]]; then
        echo "$player"
        return 0
      fi
    done
  fi

  # 2. If no player is playing but some are running, choose the highest priority one
  if [ ${#running_players[@]} -gt 0 ]; then
    # Return the first running player in the priority list
    for player in "${PLAYER_PRIORITY[@]}"; do
      if [[ " ${running_players[*]} " =~ " $player " ]]; then
        echo "$player"
        return 0
      fi
    done
  fi

  # 3. No players are running, use default from priority list
  echo "${PLAYER_PRIORITY[0]}"
  return 0
}

# Get the active player based on running status and priority
ACTIVE_PLAYER=$(determine_active_player)
log_fs_debug "Selected active player: $ACTIVE_PLAYER"

# Determine player state using the appropriate module's function
case "$ACTIVE_PLAYER" in
  "spotify")
    player_state=$(spotify_get_state)
    ;;
  "apple_music")
    player_state=$(apple_music_get_state)
    ;;
  # Future player cases here
  *)
    log_api_error "Unknown player: $ACTIVE_PLAYER"
    echo '{"error": "Unknown player"}'
    exit 1
    ;;
esac

log_state_change "$CURRENT_TRACK_FILE" "$player_state" "$ACTIVE_PLAYER is $player_state" || true

# Get current track ID if player is running
current_track_id=""
if [ "$player_state" != "closed" ]; then
  case "$ACTIVE_PLAYER" in
    "spotify")
      current_track_id=$(spotify_get_track_id)
      ;;
    "apple_music")
      current_track_id=$(apple_music_get_track_id_local)
      ;;
  esac
fi

# Handle states where we don't need to fetch full track data
case "$player_state" in
  "closed")
    # Ensure cache directory exists before writing file - suppress errors
    [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR" 2>/dev/null
    update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
    exit 0
    ;;

  "paused")
    if ! has_track_changed "$CURRENT_TRACK_FILE" "$current_track_id"; then
      # Same track, just update state
      update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
      exit 0
    fi

    track_info=""
    case "$ACTIVE_PLAYER" in
      "spotify")
        track_info=$(spotify_get_track_info "$ARTWORK_DIR" "$current_track_id")
        ;;
      "apple_music")
        track_info=$(apple_music_get_track_info "$ARTWORK_DIR" "$current_track_id")
        ;;
    esac

    if [ -n "$track_info" ]; then
      # Ensure cache directory exists before writing file - suppress errors
      [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR" 2>/dev/null
      update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state" "$track_info"
    else
      # Ensure cache directory exists before writing file - suppress errors
      [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR" 2>/dev/null
      update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
    fi
    exit 0
    ;;
esac

# For playing state, check if track has changed before fetching full info
if [ "$player_state" = "playing" ]; then
  if ! has_track_changed "$CURRENT_TRACK_FILE" "$current_track_id"; then
    # Same track still playing, just update state
    update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
    exit 0
  fi
fi

# Get full track info for new tracks or playing tracks
track_data=""
case "$ACTIVE_PLAYER" in
  "spotify")
    track_data=$(spotify_get_track_info "$ARTWORK_DIR" "$current_track_id")
    ;;
  "apple_music")
    track_data=$(apple_music_get_track_info "$ARTWORK_DIR" "$current_track_id")
    ;;
  # Future player cases here
esac

# Update cache and output
if [ -n "$track_data" ]; then
  # Validate JSON before proceeding
  if jq -e '.' <<< "$track_data" >/dev/null 2>&1; then
    # Save valid JSON to cache file
    update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state" "$track_data"
  else
    # Invalid JSON - log error and use fallback
    log_fs_error "Failed to parse track data as valid JSON"
    update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
  fi
else
  # No track data - use minimal state
  log_fs_warn "No track data received for ${ACTIVE_PLAYER}"
  update_track_state "$CURRENT_TRACK_FILE" "$ACTIVE_PLAYER" "$player_state"
fi

exit 0 # Ensure no extraneous output after this point
