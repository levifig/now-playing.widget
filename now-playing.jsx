// Now Playing for Übersicht
// v1.0 - Modern JavaScript/JSX version
//
// For more info:
// http://github.com/levifig/now-playing.widget
//
// Levi Figueira
// https://levifig.com
//
// ==================================
// Alternate/bottom-pinned layout
// Set `altLayout` to `true` to enable (see className export below)

// Widget scale: adjust to resize the entire widget proportionally
// 100 = default size, 75 = 25% smaller, 125 = 25% larger, etc.
const WIDGET_SCALE = 100;

export const command = "now-playing.widget/lib/get_track_metadata.sh";
export const refreshFrequency = 5000;

// Helper function to scale pixel values proportionally
const scale = (value) => (value * WIDGET_SCALE) / 100;

// Parse the command output and store in state
export const updateState = (event, previousState) => {
  if (!event.output) return previousState;

  try {
    const sanitizedOutput = event.output.replace(/\\/g, "\\\\");
    const track = JSON.parse(sanitizedOutput);

    console.log("Now Playing:", track);

    return { track };
  } catch (error) {
    console.error("Error parsing track data:", error);
    return previousState || { track: null };
  }
};

// Render the widget UI
export const render = ({ track }) => {
  // Handle player not running or no track data
  if (!track || track.player_running === false) {
    return <div id="now-playing" style={{ display: "none" }}></div>;
  }

  // Validate cache freshness - hide if data is stale (>10 seconds old)
  // This prevents showing outdated track info when player closes unexpectedly
  const CACHE_TIMEOUT_MS = 10000; // 2x refresh frequency
  if (track.last_updated) {
    const now = Math.floor(Date.now() / 1000); // Current Unix timestamp
    const age = now - track.last_updated;
    if (age > CACHE_TIMEOUT_MS / 1000) {
      console.log(`Cache is stale (${age}s old), hiding widget`);
      return <div id="now-playing" style={{ display: "none" }}></div>;
    }
  }

  // Determine if player is paused
  const isPaused = track.is_playing === false;

  // Set artwork background - prefer local artwork_path, fallback to artwork_url
  // This allows seamless transitions while new artwork is being downloaded
  const artworkUrl = track.artwork_path || track.artwork_url;
  const artworkStyle = artworkUrl
    ? {
        backgroundImage: `url("${artworkUrl}")`,
        backgroundSize: "cover",
        backgroundRepeat: "no-repeat",
      }
    : {};

  // Format track name for intelligent line breaking
  // Makes secondary content (parentheses, brackets, dash-separated text) smaller (80%)
  // Adds break opportunities before these elements
  const formatTrackName = (name) => {
    if (!name) return "";

    // Match patterns: ` (...)`, ` - ...`, or ` [...]` at the end
    // Prioritize the first occurrence from left to right
    const patterns = [
      { regex: /^(.+?)(\s-\s.+)$/, key: "dash" }, // ` - ` separator
      { regex: /^(.+?)(\s\[[^\]]+\].*)$/, key: "bracket" }, // ` [...]`
      { regex: /^(.+?)(\s\([^)]+\).*)$/, key: "paren" }, // ` (...)`
    ];

    for (const pattern of patterns) {
      const match = name.match(pattern.regex);
      if (match) {
        const mainTitle = match[1];
        let secondaryContent = match[2].trim();
        let prefix = " \u200B"; // Default: space + zero-width space before content

        // Special handling for dash: break after "- " instead of before
        if (pattern.key === "dash") {
          prefix = " "; // Regular space before dash
          secondaryContent = "-\u00A0\u200B" + secondaryContent.substring(1).trim(); // Dash + non-breaking space + zero-width space + text
        }

        secondaryContent = secondaryContent.replace(/\s/g, "\u00A0"); // Non-breaking spaces

        return [
          mainTitle,
          prefix,
          <span key={pattern.key} style={{ fontSize: "0.8em" }}>
            {secondaryContent}
          </span>,
        ];
      }
    }

    // No special patterns found, return as-is
    return name;
  };

  return (
    <div id="now-playing" className={isPaused ? "paused" : ""}>
      <div id="display">
        <div id="art" style={artworkStyle}></div>
        <div id="coverart"></div>
        <div id="text">
          <p id="artist">{track.artist || ""}</p>
          <p id="album">{track.album || ""}</p>
          <p id="track">{formatTrackName(track.track_name)}</p>
        </div>
      </div>
    </div>
  );
};

// Widget styles
export const className = `
  color: #fff;
  bottom: 20px;
  left: 80px;

  #now-playing {
    font-size: ${scale(16)}px;
    box-shadow: ${scale(25)}px ${scale(25)}px ${scale(50)}px ${scale(15)}px rgba(0, 0, 0, 0.5);
    border-radius: ${scale(8)}px;
    border-color: rgba(0, 0, 0, 0.8);
    position: relative;
    overflow: auto;
    background: rgba(0, 0, 0, 0.1);
  }

  p {
    margin: 0;
  }

  #display {
    padding: 0 0;
  }

  #art {
    width: ${scale(300)}px;
    height: ${scale(300)}px;
    z-index: 1;
  }

  #coverart {
    width: ${scale(300)}px;
    height: ${scale(300)}px;
    z-index: 2;
    background-image: -webkit-gradient(
      linear, left top, left bottom,
      from(rgba(0, 0, 0, 0)),
      to(rgba(0, 0, 0, 1)),
      color-stop(0.5, rgba(0, 0, 0, 0.3)),
      color-stop(0.6, rgba(0, 0, 0, 0.6)),
      color-stop(0.9, rgba(0, 0, 0, 0.9))
    );
    position: absolute;
    top: 0;
    left: 0;
  }

  #text {
    position: absolute;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Helvetica Neue", Helvetica, Arial, sans-serif;
    z-index: 3;
    left: 0;
    bottom: 0;
    padding: ${scale(18)}px;
    line-height: ${scale(15)}px;
    text-shadow: 0 0 ${scale(15)}px rgba(255, 255, 255, 0.1);
    width: 85%;
  }

  #track {
    font-weight: 700;
    margin: ${scale(5)}px 0 0;
    line-height: ${scale(18)}px;
    font-size: ${scale(18)}px;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
    word-wrap: break-word;
  }

  #artist, #album {
    font-size: ${scale(10)}px;
    line-height: ${scale(12)}px;
    overflow-x: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    color: rgba(255, 255, 255, 0.8);
    width: 100%;
  }

  #artist {
    text-transform: uppercase;
  }

  #album {
    font-size: ${scale(10)}px;
    font-style: italic;
    color: rgba(255, 255, 255, 0.6);
  }

  #now-playing.paused {
    opacity: 0.5;
  }
`;
