angular.module("prompt", []).service("prompt", ["$modal", ($modal) ->
  @show = (title, value, $scope, cb) ->
    $scope.title = title
    Modal = $modal
      scope: $scope
      animation: "am-fade-and-scale"
      template: "modal/modal_input.html"
    #The original Modal does not work properly, we have to change it as this:
    Modal.hide = () ->
      $(".modal").hide()
      $(".modal-backdrop").hide()
    $scope.hide = () ->
      Modal.hide()
      return
    $scope.printdata = () ->
      console.log $scope.newValue
    Modal.$promise.then ->
      Modal.show()
    $scope.confirm = () ->
      $scope.hide()
      cb()
])