# Now Playing for Übersicht
# (Spotify-only... for now)
#
# By:
# Levi Figueira
# http://levifig.com

# Alternate/bottom-pinned layout
# Set `alt-layout` to `true` (see `style:` section below)

command: 'now-playing.widget/scripts/get_track_metadata.sh'

refreshFrequency: 5000

render: (output) -> '''
<div id="now-playing">
  <div id="display">
    <div id="art"></div>
    <div id="coverart"></div>
    <div id="text">
      <p id="artist"></p>
      <p id="album"></p>
      <p id="track"></p>
    </div>
  </div>
</div>
'''

afterRender: ->

update: (output) ->
  if !output
    $('#now-playing').hide()
  else
    $('#now-playing').show()
    track = JSON.parse(output)
    if $('#track').text() != track.name
      $('#track').text track.name
      $('#artist').text track.artists[0].name
      $('#album').text track.album.name
      $.getScript 'now-playing.widget/scripts/jquery.textfill.min.js', ->
        $('#now-playing').textfill
          minFontPixels: 8
          maxFontPixels: 16
          explicitHeight: 40
          innerTag: '#track'
      if(track.album)
        $('#art').css
          'background-image': 'url(' + track.album.images[0].url + ')'
          'background-size': 'cover'
          'background-repeat': 'no-repeat'
   return

style: """

// Set to true for alternate layout
alt-layout = false

color: #fff
bottom: 10px
left: 90px

#now-playing
  box-shadow: 25px 25px 50px 15px rgba(0,0,0,0.5)
  border-radius: 8px
  border-color: rgba(0,0,0,0.8)
  position: relative
  overflow: auto
  background: rgba(0,0,0,0.1)

p
  margin: 0

#display
  padding:  0 0

#art
  width: 200px
  height: 200px
  z-index:1

#coverart
  width: 200px
  height: 200px
  z-index: 2
  background-image: -webkit-gradient(
    linear, left top, left bottom, from(rgba(0,0,0,0)), to(rgba(0,0,0,1)),
    color-stop(.5,rgba(0,0,0,0.3)), color-stop(.6,rgba(0,0,0,0.6)), color-stop(.9,rgba(0,0,0,0.9)));
  position: absolute
  top:0
  left:0

#text
  position: absolute
  font-family: Droid Sans, Helvetica Neue, Helvetica, Arial
  z-index: 3
  left: 0
  bottom: 0
  padding: 0.8em
  line-height: 0.7rem
  text-shadow: 0 0 15px rgba(255,255,255,0.1)

#artist, #album
  font-size: 0.6rem
  overflow-x: hidden
  whitespace: nowrap
  text-overflow: ellipsis
  color: rgba(255,255,255,0.8)
  width: 180px

#album
  font-size: 0.5rem
  font-style: italic
  color: rgba(255,255,255,0.6)

#track
  font-weight: 700
  padding-right: 20px
  margin: 0.2rem 0 0
  line-height: 1.1em

if alt-layout
  bottom: 0px
  #now-playing
    border-radius: 8px 8px 0 0
  #text
    padding: 0.8em 0.8em 0.4em
"""
