angular.module("mouseCapture", []).factory("mouseCapture", ($rootScope) ->
  target = document
  mouseCaptureConfig = null
  mouseMove = (evt) ->
    if mouseCaptureConfig and mouseCaptureConfig.mouseMove
      mouseCaptureConfig.mouseMove evt
      $rootScope.$digest()
    return
  mouseUp = (evt) ->
    if mouseCaptureConfig and mouseCaptureConfig.mouseUp
      mouseCaptureConfig.mouseUp evt
      $rootScope.$digest()
    return
  registerElement: (element) ->
    target = element
    return
  acquire: (evt, config) ->
    @release()
    mouseCaptureConfig = config
    target.mousemove mouseMove
    target.mouseup mouseUp
    return
  release: ->
    if mouseCaptureConfig
      mouseCaptureConfig.released()  if mouseCaptureConfig.released
      mouseCaptureConfig = null
    target.unbind "mousemove", mouseMove
    target.unbind "mouseup", mouseUp
    return
).directive "mouseCapture", ->
  restrict: "A"
  controller: ($scope, $element, $attrs, mouseCapture) ->
    # Register the directives element as the mouse capture element.
    mouseCapture.registerElement $element