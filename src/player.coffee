# get the youtube api
callbacks = []
ytApi     = $('<script>')
ytApi.attr 'src', "//www.youtube.com/iframe_api"
$('script').parent().append ytApi

# callback when api has loaded
@onYouTubeIframeAPIReady = ->
  callback() for callback in callbacks

@Player = (domEl, videoId, options) ->
  options ?= {}
  domEl    = $(domEl)

  domEl.html "
    <div class='yt-player'></div>
    <div class='controls'>
      <div class='play'></div>
      <div class='pause'></div>
    </div>
  "

  controls    = domEl.find '.controls'
  playerEl    = domEl.find '.yt-player'
  playButton  = controls.find '.play'
  pauseButton = controls.find '.pause'


  player   = null
  play     = false
  destroy  = false
  api      = {}

  init = ->
    newYTPlayer()
    domEl.css 'background-image': "url(#{thumbnailUrl()})"
    domEl.css width: options.width, height: options.height

  playerReady = (event) ->
    player   = event.target 
    
    if destroy
      player.destroy()
      return

    playerEl = domEl.find('.yt-player')

    api[name] = prop for name, prop of player

    player.playVideo() if play
    play = false
    callback?(player)

  api.resize = (width, height) ->
    domEl.css width: width, height: height
    playerEl.css width: width, height: height
    playerEl.attr('width', width).attr('height', height)
    domEl.blur()

  # once the player loaded, this will be overridden by the
  # actual play method
  api.playVideo = ->
    console.debug 'ayay'
    domEl.addClass 'buffering'
    play = true

  api.pauseVideo = ->
    domEl.removeClass 'buffering'
    play = false

  api.destroy = ->
    destroy = true

  newYTPlayer = ->
    options = $.extend {
      videoId: videoId
      playerVars:
        html5: 1
        modestbranding: 1
        showinfo: 0
        wmode: 'transparent'
        controls: 0
      events:
        'onReady': playerReady
        'onStateChange': onPlayerStateChange
    }, options
          
    new YT.Player playerEl[0], options


  onPlayerStateChange = (event) ->
    if event.data == YT.PlayerState.PLAYING
      domEl.addClass 'playing'
      domEl.removeClass('paused').removeClass('buffering')
    else if event.data == YT.PlayerState.BUFFERING
      domEl.find('.ythack').remove()
      domEl.addClass 'buffering'
    else if event.data == YT.PlayerState.PAUSED
      domEl.removeClass('playing').removeClass('buffering')
      domEl.addClass('paused')

  thumbnailUrl = ->
    "http://img.youtube.com/vi/#{videoId}/0.jpg"


  # events 

  playButton.on  'click', -> api.playVideo()
  pauseButton.on 'click', -> api.pauseVideo()

  if YT? then init() else callbacks.push init

  api