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

export const command = "now-playing.widget/lib/get_track_metadata.sh";

export const refreshFrequency = 5000;

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

  // Set artwork background if available
  const artworkStyle = track.artwork_url
    ? {
        backgroundImage: `url(${track.artwork_url})`,
        backgroundSize: "cover",
        backgroundRepeat: "no-repeat",
      }
    : {};

  // Format track name for intelligent line breaking
  // Inserts zero-width space before parentheses to create preferred break points
  // This keeps parenthetical content together while allowing breaks when needed
  const formatTrackName = (name) => {
    if (!name) return "";
    // Insert zero-width space after space and before opening parenthesis
    // Browser will only break here if needed, otherwise stays on one line
    return name.replace(/\s\(/g, " \u200B(");
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
  bottom: 30px;
  left: 90px;

  #now-playing {
    box-shadow: 25px 25px 50px 15px rgba(0, 0, 0, 0.5);
    border-radius: 8px;
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
    width: 300px;
    height: 300px;
    z-index: 1;
  }

  #coverart {
    width: 300px;
    height: 300px;
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
    font-family: Roboto, Helvetica Neue, Helvetica, Arial;
    z-index: 3;
    left: 0;
    bottom: 0;
    padding: 0.8em;
    line-height: 0.7rem;
    text-shadow: 0 0 15px rgba(255, 255, 255, 0.1);
    width: 85%;
  }

  #track {
    font-weight: 700;
    padding-right: 20px;
    margin: 0 0 0.3rem 0;
    line-height: 1.2em;
    font-size: clamp(0.7rem, 1.5vw, 1.1rem);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  #artist, #album {
    font-size: clamp(0.5rem, 1.2vw, 0.7rem);
    overflow-x: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    color: rgba(255, 255, 255, 0.8);
    width: 100%;
    margin: 0.1rem 0;
  }

  #album {
    font-size: clamp(0.4rem, 1vw, 0.6rem);
    font-style: italic;
    color: rgba(255, 255, 255, 0.6);
  }

  #now-playing.paused {
    opacity: 0.7;
  }
`;

// Alternate layout - uncomment the lines below to enable bottom-pinned layout
// Simply replace the className export above with this one:
/*
export const className = `
  color: #fff;
  bottom: 0px;
  left: 90px;

  #now-playing {
    box-shadow: 25px 25px 50px 15px rgba(0, 0, 0, 0.5);
    border-radius: 8px 8px 0 0;
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
    width: 300px;
    height: 300px;
    z-index: 1;
  }

  #coverart {
    width: 300px;
    height: 300px;
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
    font-family: Droid Sans, Helvetica Neue, Helvetica, Arial;
    z-index: 3;
    left: 0;
    bottom: 0;
    padding: 0.8em 0.8em 0.4em;
    line-height: 0.7rem;
    text-shadow: 0 0 15px rgba(255, 255, 255, 0.1);
    width: 85%;
  }

  #track {
    font-weight: 700;
    padding-right: 20px;
    margin: 0 0 0.3rem 0;
    line-height: 1.2em;
    font-size: clamp(0.7rem, 1.5vw, 1.1rem);
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  #artist, #album {
    font-size: clamp(0.5rem, 1.2vw, 0.7rem);
    overflow-x: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    color: rgba(255, 255, 255, 0.8);
    width: 100%;
    margin: 0.1rem 0;
  }

  #album {
    font-size: clamp(0.4rem, 1vw, 0.6rem);
    font-style: italic;
    color: rgba(255, 255, 255, 0.6);
  }

  #now-playing.paused {
    opacity: 0.5;
  }
`;
*/
