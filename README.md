# Now Playing Widget for Übersicht

A sleek Now Playing widget for [Übersicht](http://tracesof.net/uebersicht/) that displays the current track information along with album artwork.

Currently supports:
- Spotify
- Apple Music

Inspired by long abandoned apps like [Bowtie](http://bowtieapp.com/) and [CoverSutra](http://sophiestication.com/coversutra/), but focused solely on track information display, not control (I never really used those apps to control my media player).

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

Player priority is currently set in `lib/get_track_metadata.sh` (line 24: `PLAYER_PRIORITY`).

## Customization

### Alternate Layout

For an alternate layout (pinned to the bottom of the screen), edit `now-playing.jsx` and replace the `className` export with the commented alternate version at the bottom of the file (around line 200).

### Size and Appearance

All styling is configured in the `className` export in `now-playing.jsx`:
- Adjust the width and height values to change the widget size
- Modify the border-radius property to change the corner roundness
- Customize colors, fonts, shadows, and positioning as desired

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
