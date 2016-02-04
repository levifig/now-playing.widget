# Now Playing Widget

## Motivation
I couldn't find any Übersicht widgets for Spotify that included the album's 
artwork so I decided to make one.

Inspired by long abandoned apps like [Bowtie](http://bowtieapp.com/) and 
[CoverSutra](http://sophiestication.com/coversutra/), but focused on track 
information, not control (both because of Übersicht limitations, but also 
because I never really used those apps for controlling my music player).

## Caveats
This is basically polling Spotify's API every time it updates so be gentle.
I've set the default refresh rate to 5 seconds but I don't know how nice
Spotify is with folks pulling a 640px cover every 5 seconds. I definitely
have thought of implementing some sort of caching mechanism, but that's a bit
above my "pay grade" (help welcome and encourage *wink* *wink*).


## Screenshot
![Screenshot](http://raw.github.com/levifig/now-playing.widget/master/screenshot.png)


## TODO
- CACHING, CACHING, CACHING
- iTunes support
- Better error handling
