((that) ->
  that.open_twitter = (url) ->
    width = 450
    height = 250
    sw = screen.width
    sh = screen.height
    left = (sw - width - 20) / 2
    top = (sh - height - 20) / 2
    window.open url, "intent", "toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,resizable=yes,width=#{width},height=#{height},left=#{left},top=#{top}"
)(this)
