app.controller('markController', ['$scope', '$request', ($scope, $request) ->
  $scope.s = ''
  $scope.ts = ''
  $scope.connecting = false

  $scope.submit = ->
    $scope.connecting = true

    $request.send('/mark_all_as_read', { s : $scope.s, ts : $scope.ts }, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body), ->
      $scope.connecting = false)

]);