# Now Playing Widget for Übersicht

A sleek Spotify Now Playing widget for [Übersicht](http://tracesof.net/uebersicht/) that displays the current track information along with album artwork.

Inspired by long abandoned apps like [Bowtie](http://bowtieapp.com/) and [CoverSutra](http://sophiestication.com/coversutra/), but focused solely on track information display, not control (I never really used those apps to control my media player).


## Screenshots

![Normal Display](http://raw.github.com/levifig/now-playing.widget/master/screenshot.png)

![Truncated & Resized](http://raw.github.com/levifig/now-playing.widget/master/screenshot-2.png)

![Alternate/Pinned Layout](http://raw.github.com/levifig/now-playing.widget/master/screenshot-3.png)

## Installation

Download [ZIP archive](https://github.com/levifi/now-playing.widget/archive/master.zip) to your Übersicht widgets folder (i.e. `~/Library/Application Support/Übersicht/widgets`).

## Setting Up Spotify API Access

This widget requires Spotify API credentials to function properly. Follow these steps to set up your own Spotify Developer App:

1. **Create a Spotify Developer Account**
   - Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/)
   - Log in with your Spotify account or create one if needed

2. **Create a New App**
   - Click "Create an App" on the dashboard
   - Fill in the app name (e.g., "Übersicht Now Playing Widget") and description
   - For "Which API/SDKs are you planning to use?", select "Web API"
   - Set the Redirect URI to `http://localhost:8888/callback` (this won't be used but is required)
   - Accept the terms and create the app

3. **Get Your Credentials**
   - Once your app is created, you'll see your Client ID on the dashboard
   - Click "Show Client Secret" to reveal your Client Secret
   - Copy both the Client ID and Client Secret

4. **Add Credentials to the Widget**
   - Open the `now-playing.widget/lib/get_track_metadata.sh` file
   - Replace the placeholder values with your actual credentials:
     ```
     # Spotify API credentials
     CLIENT_ID="your_client_id_here"
     CLIENT_SECRET="your_client_secret_here"
     ```

5. **Make the Script Executable**
   - Open Terminal
   - Run: `chmod +x ~/Library/Application\ Support/Übersicht/widgets/now-playing.widget/lib/get_track_metadata.sh`

## Customization

### Alternate Layout
For alternate layout (pinned to the bottom of the screen, as seen in the third screenshot above), edit `now-playing.coffee` and just below `style:`, in line 59, change the `alt-layout` variable value to `true` (default is `false`).

### Size and Appearance
- Adjust the width and height values in the style section to change the widget size
- Modify the border-radius property to change the corner roundness

## Troubleshooting

If the widget doesn't display:
- Make sure Spotify is running and playing a track
- Check that your API credentials are correctly entered
- Verify that the script has execution permissions

## Contributing

If you have ideas for improvements or fixes, please open a PR.
