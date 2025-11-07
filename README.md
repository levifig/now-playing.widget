# Now Playing Widget for Übersicht

A sleek Now Playing widget for [Übersicht](http://tracesof.net/uebersicht/) that displays the current track information along with album artwork.

Currently supports:
- Spotify
- Apple Music

Inspired by long abandoned apps like [Bowtie](http://bowtieapp.com/) and [CoverSutra](http://sophiestication.com/coversutra/), but focused solely on track information display, not control (I never really used those apps to control my media player).

## Features

- **Proportional Scaling**: Resize the entire widget with a single constant while maintaining visual consistency
- **Intelligent Track Formatting**: Automatically styles secondary content (parentheses, brackets, dash-separated text) at 80% size with smart line breaking
- **Optimized Artwork**:
  - Apple Music uses base64 data URLs for instant artwork display
  - Spotify uses smart URL-based caching to avoid redundant downloads
- **Modern Typography**: Apple system fonts for native macOS integration
- **Reliable Player Detection**: Uses `pgrep` for robust process detection
- **Unified State Management**: All track and state information stored in a single JSON file
- **Configurable Logging**: Multiple log levels with automatic rotation and retention management

## Installation

1. Make sure you have [Übersicht](http://tracesof.net/uebersicht/) installed
2. Clone this repository to your Übersicht widgets folder:

   ```bash
   git clone https://github.com/levifig/now-playing.widget.git $HOME/Library/Application\ Support/Übersicht/widgets/now-playing.widget
   ```

3. That's it! The widget works out of the box with no additional configuration required.

Alternatively, download the [ZIP archive](https://github.com/levifig/now-playing.widget/archive/master.zip) and extract it into your Übersicht widgets folder (i.e. `~/Library/Application Support/Übersicht/widgets`).

## Player Priority

When multiple music players are running at the same time, the widget will display information based on player priority. The default priority is:

1. Spotify
2. Apple Music

The first player in the list gets priority when multiple players are active. If only one player is running or playing, that player will be displayed regardless of priority.

Player priority is currently set in `lib/get_track_metadata.sh` (line 29: `PLAYER_PRIORITY`).

## Customization

### Widget Size

The widget includes a proportional scaling system for easy resizing. Edit the `WIDGET_SCALE` constant in `now-playing.jsx` (line 16):

```javascript
const WIDGET_SCALE = 100;  // Default size
```

- `100` = default size (300×300px)
- `75` = 25% smaller (225×225px)
- `125` = 25% larger (375×375px)

All elements (text, spacing, shadows) scale proportionally, maintaining visual consistency at any size.

### Advanced Styling

For detailed customization, all styling is configured in the `className` export in `now-playing.jsx`:
- Colors, fonts, and shadows
- Widget positioning (default: bottom-left)
- Opacity when paused

## Logging

The widget includes simple logging for debugging. Edit the constants at the top of `lib/logging.sh` to configure:

- **`LOG_MODE`**: Set to `OFF`, `ERROR`, `WARN`, `INFO`, or `DEBUG` (default: `ERROR`)
- **`LOG_RETENTION_DAYS`**: Days to keep old logs (default: 7)
- **`LOG_MAX_SIZE_MB`**: Max log size before rotation (default: 5MB)

Logs are stored in the `logs/` directory with automatic rotation (`api.log` → `api.1.log` → `api.2.log`, etc.). Higher numbers indicate older log files.

## Troubleshooting

### Widget Not Updating

If the widget isn't updating with the current track:

1. Make sure your music player (Spotify or Apple Music) is running and playing music
2. Check the widget's console output for errors in Übersicht
3. Refresh the widget in Übersicht
4. Enable debug logging in `lib/logging.sh` and check the logs

### Permissions Issues

The widget uses AppleScript to communicate with your music players. If you encounter permission issues, ensure Übersicht has the necessary accessibility permissions in System Preferences > Security & Privacy > Privacy > Automation.

## Privacy and Security

The widget uses macOS AppleScript to retrieve track information directly from Spotify and Apple Music. No data is sent to any external servers. All communication happens locally on your machine.

## Acknowledgments

- [Übersicht](http://tracesof.net/uebersicht/)
- [jq](https://stedolan.github.io/jq/) for JSON processing

## License

This project is licensed under the MIT License - see the LICENSE file for details.
