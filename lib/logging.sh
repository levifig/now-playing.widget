#!/usr/bin/env bash

# Simple logging system for now-playing widget
# Compatible with bash 3.2+

# ===== USER CONFIGURATION =====
LOG_MODE="ERROR"         # OFF, ERROR, WARN, INFO, DEBUG
LOG_RETENTION_DAYS=7     # Days to keep logs before deletion
LOG_MAX_SIZE_MB=5        # Max log size in MB before rotation
# ==============================

# Log levels (numeric for comparison)
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Global variables set by init_logging
LOG_DIR=""
API_LOG=""
FS_LOG=""

# Convert log mode string to numeric level
_get_numeric_level() {
  case "${LOG_MODE^^}" in
    OFF)   echo 0 ;;
    ERROR) echo "$LOG_LEVEL_ERROR" ;;
    WARN)  echo "$LOG_LEVEL_WARN" ;;
    INFO)  echo "$LOG_LEVEL_INFO" ;;
    DEBUG) echo "$LOG_LEVEL_DEBUG" ;;
    *)     echo "$LOG_LEVEL_ERROR" ;;
  esac
}

# Check if we should log at this level
_should_log() {
  local level=$1
  local current_level=$(_get_numeric_level)
  [ "$current_level" -gt 0 ] && [ "$level" -le "$current_level" ]
}

# Rotate a log file using numbered scheme (api.log -> api.1.log -> api.2.log, etc.)
_rotate_log() {
  local log_file=$1

  [ ! -f "$log_file" ] && return 0

  # Check file size (in bytes)
  local file_size
  if stat --version &>/dev/null 2>&1; then
    # GNU stat
    file_size=$(stat -c "%s" "$log_file" 2>/dev/null || echo 0)
  else
    # BSD stat (macOS)
    file_size=$(stat -f "%z" "$log_file" 2>/dev/null || echo 0)
  fi

  # Convert MB to bytes for comparison
  local max_size_bytes=$((LOG_MAX_SIZE_MB * 1024 * 1024))

  # If file is smaller than max size, no rotation needed
  [ "$file_size" -lt "$max_size_bytes" ] && return 0

  # Find highest numbered log file
  local base_name="${log_file%.*}"
  local extension="${log_file##*.}"
  local max_num=0

  for f in "${base_name}".*.${extension}; do
    [ -f "$f" ] || continue
    local num=$(echo "$f" | sed "s/${base_name}\.\([0-9]*\)\.${extension}/\1/")
    [ "$num" -gt "$max_num" ] && max_num="$num"
  done

  # Rotate existing numbered files (increment by 1)
  for ((i = max_num; i >= 1; i--)); do
    local old_file="${base_name}.${i}.${extension}"
    local new_file="${base_name}.$((i + 1)).${extension}"
    [ -f "$old_file" ] && mv "$old_file" "$new_file"
  done

  # Move current log to .1
  mv "$log_file" "${base_name}.1.${extension}"

  # Create fresh log file
  touch "$log_file"
}

# Clean old numbered log files based on retention period
_cleanup_old_logs() {
  local log_dir=$1

  [ ! -d "$log_dir" ] && return 0

  # Find and remove numbered log files older than retention period
  find "$log_dir" -type f -name "*.*.log" -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null
}

# Core logging function
_log() {
  local level=$1
  local category=$2
  local message=$3
  local log_file=$4

  # Check if we should log at this level
  _should_log "$level" || return 0

  # Ensure log file exists
  [ -z "$log_file" ] && return 1

  # Create log directory if needed
  local log_dir=$(dirname "$log_file")
  [ ! -d "$log_dir" ] && mkdir -p "$log_dir" 2>/dev/null

  # Rotate log if needed
  _rotate_log "$log_file"

  # Format: YYYY-MM-DD HH:MM:SS [LEVEL] Category: Message
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local level_name
  case "$level" in
    1) level_name="ERROR" ;;
    2) level_name="WARN" ;;
    3) level_name="INFO" ;;
    4) level_name="DEBUG" ;;
    *) level_name="UNKNOWN" ;;
  esac

  echo "${timestamp} [${level_name}] ${category}: ${message}" >> "$log_file"
}

# Public logging functions - API category
log_api_error() {
  _log "$LOG_LEVEL_ERROR" "API" "$1" "$API_LOG"
}

log_api_warn() {
  _log "$LOG_LEVEL_WARN" "API" "$1" "$API_LOG"
}

log_api_info() {
  _log "$LOG_LEVEL_INFO" "API" "$1" "$API_LOG"
}

log_api_debug() {
  _log "$LOG_LEVEL_DEBUG" "API" "$1" "$API_LOG"
}

# Public logging functions - Filesystem category
log_fs_error() {
  _log "$LOG_LEVEL_ERROR" "FS" "$1" "$FS_LOG"
}

log_fs_warn() {
  _log "$LOG_LEVEL_WARN" "FS" "$1" "$FS_LOG"
}

log_fs_info() {
  _log "$LOG_LEVEL_INFO" "FS" "$1" "$FS_LOG"
}

log_fs_debug() {
  _log "$LOG_LEVEL_DEBUG" "FS" "$1" "$FS_LOG"
}

# Backward compatibility - map old functions to new ones
log_api() {
  log_api_info "$1"
}

log_fs() {
  log_fs_info "$1"
}

# Initialize logging system
init_logging() {
  local log_dir=$1
  local api_log=$2
  local fs_log=$3

  # Export for use by logging functions
  LOG_DIR="$log_dir"
  API_LOG="$api_log"
  FS_LOG="$fs_log"

  # Only proceed if logging is enabled
  local current_level=$(_get_numeric_level)
  [ "$current_level" -eq 0 ] && return 0

  # Create log directory
  mkdir -p "$log_dir" 2>/dev/null

  # Clean up old numbered logs on initialization
  _cleanup_old_logs "$log_dir"

  # Touch log files if they don't exist
  [ ! -f "$api_log" ] && touch "$api_log" 2>/dev/null
  [ ! -f "$fs_log" ] && touch "$fs_log" 2>/dev/null

  return 0
}
