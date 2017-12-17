# Service used to help with dragging and clicking on elements.
angular.module("dragging", ["mouseCapture"]).factory "dragging", ($rootScope, mouseCapture) ->
  # Threshold for dragging.
  # When the mouse moves by at least this amount dragging starts.
  threshold = 1
  # Called by users of the service to register a mousedown event and start dragging.
  # Acquires the 'mouse capture' until the mouseup event.
  startDrag: (evt, config) ->
    dragging = false
    x = evt.pageX
    y = evt.pageY
    # Handler for mousemove events while the mouse is 'captured'.
    mouseMove = (evt) ->
      unless dragging
        if Math.abs(evt.pageX - x) > threshold or Math.abs(evt.pageY - y) > threshold
          dragging = true
          config.dragStarted x, y, evt  if config.dragStarted
          # First 'dragging' call to take into account that we have
          # already moved the mouse by a 'threshold' amount.
          config.dragging evt.pageX, evt.pageY, evt  if config.dragging
      else
        config.dragging evt.pageX, evt.pageY, evt  if config.dragging
        x = evt.pageX
        y = evt.pageY
      return
    # Handler for when mouse capture is released.
    released = ->
      if dragging
        config.dragEnded()  if config.dragEnded
      else
        config.clicked()  if config.clicked
      return
    # Handler for mouseup event while the mouse is 'captured'.
    # Mouseup releases the mouse capture.
    mouseUp = (evt) ->
      mouseCapture.release()
      evt.stopPropagation()
      evt.preventDefault()
      return
    # Acquire the mouse capture and start handling mouse events.
    mouseCapture.acquire evt,
      mouseMove: mouseMove
      mouseUp: mouseUp
      released: released
    evt.stopPropagation()
    evt.preventDefault()
    return
