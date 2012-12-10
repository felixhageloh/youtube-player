# get the youtube api
ytApi     = document.createElement('script')
ytApi.src = "//www.youtube.com/iframe_api"
scriptTag = document.getElementsByTagName('script')[0]
scriptTag.parentNode.insertBefore(ytApi, scriptTag)

Player = (domEl, youtubeId) ->
  