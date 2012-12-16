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
      <div class='scrubber slider'>
        <div class='track'>
          <div class='progress'></div>
        </div>
        <div class='knob'></div>
      </div>
      <div class='volume slider'>
        <div class='track'>
          <div class='progress'></div>
        </div>
        <div class='knob'>
      </div></div>
    </div>
  "

  controls     = domEl.find '.controls'
  playerEl     = domEl.find '.yt-player'
  playButton   = controls.find '.play'
  pauseButton  = controls.find '.pause'
  scrubberEl   = controls.find '.scrubber'
  volumeEl     = controls.find '.volume'


  player       = null
  scrubber     = null
  volumeSlider = null
  
  play     = false
  destroy  = false
  api      = {}

  updateTimer    = null
  updateInterval = 50 #ms


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

    scrubber     = Slider scrubberEl, onScrubberChange
    volumeSlider = Slider volumeEl,   onVolumeSliderChange

    volumeSlider.moveTo player.getVolume()/100

    api[name] = prop for name, prop of player

    player.playVideo() if play
    play = false
    callback?(player)

  onScrubberChange = (pct, released = false) ->
    return unless player

    setTimeout ->
      player.seekTo pct.x * player.getDuration(), released

  onVolumeSliderChange = (pct, released = false) ->
    return unless player

    player.setVolume pct.x * 100
    

  api.resize = (width, height) ->
    domEl.css width: width, height: height
    playerEl.css width: width, height: height
    playerEl.attr('width', width).attr('height', height)
    domEl.blur()

  # once the player loaded, this will be overridden by the
  # actual play method
  api.playVideo = ->
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
        iv_load_policy: 3
        hd: 1
      events:
        'onReady': playerReady
        'onStateChange': onPlayerStateChange
    }, options
          
    new YT.Player playerEl[0], options


  playbackPct = ->
    return unless player
    player.getCurrentTime() / player.getDuration()

  startUpdating = ->
    updateTimer = setInterval ->
      scrubber.moveTo playbackPct()
    , updateInterval

  stopUpdating = ->
    clearInterval updateInterval if updateInterval

  onPlayerStateChange = (event) ->
    if event.data == YT.PlayerState.PLAYING
      domEl.addClass 'playing'
      domEl.removeClass('paused').removeClass('buffering')
      scrubber.moveTo playbackPct()
      startUpdating()
    else if event.data == YT.PlayerState.BUFFERING
      domEl.addClass 'buffering'
    else if event.data == YT.PlayerState.PAUSED
      domEl.removeClass('playing').removeClass('buffering')
      domEl.addClass('paused')
      stopUpdating()
      scrubber.moveTo playbackPct()

  thumbnailUrl = ->
    "http://img.youtube.com/vi/#{videoId}/0.jpg"

  # events 
  playButton.on  'click', -> api.playVideo()
  pauseButton.on 'click', -> api.pauseVideo()


  Slider = (domEl, callback, options = {}) ->
    track          = domEl.find '.track'
    knob           = domEl.find '.knob'
    progressBar    = domEl.find '.progress'

    startPoint     = null
    startPos       = null
    currentPos     = x: 0, y: 0
    dragging       = false

    options.dragX ?= true
    options.dragY ?= false

    trackRect        = track.offset()
    trackRect.width  = track.width()
    trackRect.height = track.height()

    minX = 0
    maxX = trackRect.width  - knob.width()
    minY = 0
    maxY = trackRect.height - knob.height()

    constrain = (value, dimension) ->
      if dimension == 'x'
        Math.max minX, Math.min(maxX, value)
      else if dimension == 'y'
        Math.max minY, Math.min(maxY, value)

    startDrag = (e) ->
      startPoint = x: e.pageX, y: e.pageY
      startPos   = x: parseInt(knob.css 'left'), y: parseInt(knob.css 'top')
      startPos.x = 0 if isNaN startPos.x
      startPos.y = 0 if isNaN startPos.y
      currentPos = $.extend {}, startPos

      dragging = true

      $(document).on 'mousemove', updateDrag
      $(document).on 'mouseup',   endDrag

    updateDrag = (e) ->
      if options.dragX
        x = e.pageX - startPoint.x
        currentPos.x = constrain(startPos.x+x, 'x')
        
      if options.dragY
        y = constrain e.pageY - startPoint.y, 'y'
        currentPos.x = constrain(startPos.y+y, 'y')

      render()
      callback positionPct()

    trackClicked = (e) ->
      return if dragging
      currentPos.x = e.pageX - trackRect.left if options.dragX
      currentPos.y = e.pageY - trackRect.top  if options.dragY

      render()
      callback positionPct(), true

    endDrag = (e) ->
      $(document).off 'mousemove', updateDrag
      $(document).off 'mouseup',   endDrag

      callback positionPct(), true
      setTimeout (-> dragging = false), 200

    positionPct = ->
      x: currentPos.x / (maxX - minX)
      y: currentPos.y / (maxY - minY)

    render = ->
      scale = 
        x: (if options.dragX then positionPct().x else 1)
        y: (if options.dragY then positionPct().y else 1)
      progressBar.css webkitTransform: "scale(#{scale.x}, #{scale.y})"
      knob.css 
        left: if options.dragX then currentPos.x else null
        top:  if options.dragY then currentPos.y else null

    moveTo = (pct) ->
      return if dragging
      currentPos.x = pct * (maxX - minX) if options.dragX
      currentPos.y = pct * (maxY - minY) if options.dragY

      render()


    knob.on 'mousedown', startDrag
    track.on 'click', trackClicked

    moveTo: moveTo


  if YT? then init() else callbacks.push init

  api