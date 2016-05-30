# Now Playing Widget

## Motivation
I couldn't find any [Übersicht](http://tracesof.net/uebersicht/) widgets 
for [Spotify](https://www.spotify.com) that included the album's artwork so
I decided to make one.

Inspired by long abandoned apps like [Bowtie](http://bowtieapp.com/) and
[CoverSutra](http://sophiestication.com/coversutra/), but focused solely
on track information display, not control (I never really used those apps
to control my media player).


## Screenshots
![Normal Display](http://raw.github.com/levifig/now-playing.widget/master/screenshot.png)

![Truncated & Resized](http://raw.github.com/levifig/now-playing.widget/master/screenshot-2.png)

![Alternate/Pinned Layout](http://raw.github.com/levifig/now-playing.widget/master/screenshot-3.png)


## Usage
Download [ZIP archive](https://github.com/levifig/now-playing.widget/archive/master.zip) to your Übersicht widgets folder (i.e. `~/Library/Application Support/Übersicht/widgets`).

For alternate layout (pinned to the bottom of the screen, as seen in the third screenshot above), edit `now-playing.coffee` and just below `style:`, in line 59, change the `alt-layout` variable value to `true` (default is `false`).


## Caveats
This is basically polling Spotify's API every time it updates so be gentle.
I've set the default refresh rate to 5 seconds but I don't know how nice
Spotify is with folks pulling a 640px cover every 5 seconds. I have definitely
[thought of implementing some sort of caching system](https://github.com/levifig/now-playing.widget/issues/2)
but haven't decided how to tackle that issue... yet. :)


## Disclaimer
I'm a _hacker_ not a _legit programmer_ (whatever that means). I reused &
remixed bits and pieces from several sources. I have some experience with
Bash and Javascript, but had never ventured into Coffeescript (though I
use and love Ruby). I was pleasantly surprised and enjoyed using it
but I might've made some crude mistakes in syntax or logic. Use this
at your own risk... :P


## Acknowledgements
I initially started by customizing Patrick Pan's
[Last.FM widget](http://tracesof.net/uebersicht-widgets/#lastfm) but then
decided to move away from using Last.FM and finding ways to pull the information
directly from the Spotify app and Spotify's API. But I definitely think Patrick
deserves the above acknowledgement for having designed the structure that I
reused and remixed in the making of this widget.


## Contributing
If you have ideas for improvements and, especially, fixes, please open a PR
and I'll definitely consider them. I do appreciate your help in advance.


## TODO
- [CACHING, CACHING, CACHING](https://github.com/levifig/now-playing.widget/issues/2)
- iTunes support
- Better error handling
